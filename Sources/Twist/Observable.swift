//===--- Observable.swift ----------------------------------------------===//
//Copyright (c) 2016 Crossroad Labs s.r.o.
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//===----------------------------------------------------------------------===//

import Foundation

import ExecutionContext
import Event

public protocol AccessableProtocol {
    associatedtype Payload
    
    func async(_ f:@escaping (Payload)->Void)
}

public enum ObservableWillChangeEvent<T> : Event {
    public typealias Payload = T
    case event
}

public enum ObservableDidChangeEvent<T> : Event {
    public typealias Payload = T
    case event
}

public struct ObservableEventGroup<T, E : Event> {
    fileprivate let event:E
    
    private init(_ event:E) {
        self.event = event
    }
    
    public static var willChange:ObservableEventGroup<T, ObservableWillChangeEvent<T>> {
        return ObservableEventGroup<T, ObservableWillChangeEvent<T>>(.event)
    }
    
    public static var didChange:ObservableEventGroup<T, ObservableDidChangeEvent<T>> {
        return ObservableEventGroup<T, ObservableDidChangeEvent<T>>(.event)
    }
}

public protocol ObservableProtocol : EventEmitter, SignalStreamProtocol {
    associatedtype Payload
    typealias ChangePayload = (Payload, Payload)
    
    func on(_ groupedEvent: ObservableEventGroup<ChangePayload, ObservableWillChangeEvent<ChangePayload>>) -> SignalStream<ChangePayload>
    func on(_ groupedEvent: ObservableEventGroup<ChangePayload, ObservableDidChangeEvent<ChangePayload>>) -> SignalStream<ChangePayload>
}

public extension ObservableProtocol {
    public var stream:SignalStream<Payload> {
        get {
            return self.on(.didChange).map {(_, value) in value}
        }
    }
}

public extension ObservableProtocol where Self : AccessableProtocol {
    var stream:SignalStream<Payload> {
        get {
            let node = SignalNode<Payload>(context: context)
            //TODO: WTF?
            let off = self.on(.didChange).map {(_, value) in value}.pour(to: node)
            async { value in
                node <= value
            }
            return node
        }
    }
}

public extension ObservableProtocol {
    public func react(_ f: @escaping Handler) -> Off {
        return self.on(.didChange).map {(_, value) in value}.react(f)
    }
}

public extension ObservableProtocol where Self : AccessableProtocol {
    public func react(_ f: @escaping Handler) -> Off {
        let off = self.on(.didChange).map {(_, value) in value}.react(f)
        async(f)
        return off
    }
}

public protocol MutableObservableProtocol : ObservableProtocol, AccessableProtocol, SignalNodeProtocol {
    //function passed for mutation
    typealias Mutator = (Payload) -> Void
    
    //current, mutator
    func async(_ f:@escaping (Payload, Mutator)->Void)
    func sync(_ f:@escaping (Payload, Mutator)->Void) -> Payload
}

public extension MutableObservableProtocol {
    func sync() -> Payload {
        return sync {_,_ in}
    }
}

public extension AccessableProtocol where Self : MutableObservableProtocol {
    public func async(_ f:@escaping (Payload)->Void) {
        self.async { value, _ in
            f(value)
        }
    }
}

public protocol ParametrizableObservableProtocol : ObservableProtocol {
    typealias Subscriber = (Bool) -> SignalStream<ChangePayload>
    
    init(context:ExecutionContextProtocol, subscriber:@escaping Subscriber)
}

public protocol ParametrizableMutableObservableProtocol : ParametrizableObservableProtocol, MutableObservableProtocol {
    typealias Accessor = () -> Payload
    typealias Mutator = (Payload) -> Void
    
    init(context:ExecutionContextProtocol, subscriber:@escaping Subscriber, accessor:@escaping Accessor, mutator:@escaping Mutator)
}

public class ReadonlyObservable<T> : ParametrizableObservableProtocol {
    public typealias Payload = T
    public typealias ChangePayload = (Payload, Payload)
    //early if true, late otherwise
    public typealias Subscriber = (Bool) -> SignalStream<ChangePayload>
    
    public let dispatcher:EventDispatcher = EventDispatcher()
    public let context: ExecutionContextProtocol
    
    private let _subscriber:Subscriber
    
    public required init(context:ExecutionContextProtocol, subscriber:@escaping Subscriber) {
        self.context = context
        self._subscriber = subscriber
    }
    
    public func on(_ groupedEvent: ObservableEventGroup<ChangePayload, ObservableWillChangeEvent<ChangePayload>>) -> SignalStream<ChangePayload> {
        return _subscriber(true)
    }
    
    public func on(_ groupedEvent: ObservableEventGroup<ChangePayload, ObservableDidChangeEvent<ChangePayload>>) -> SignalStream<ChangePayload> {
        return _subscriber(false)
    }
}

public class MutableObservable<T> : ReadonlyObservable<T>, ParametrizableMutableObservableProtocol {
    public typealias ChangePayload = (Payload, Payload)
    public typealias Accessor = () -> Payload
    public typealias Mutator = (Payload) -> Void
    
    private let _accessor:Accessor
    private let _mutator:Mutator
    
    public required init(context:ExecutionContextProtocol, subscriber:@escaping Subscriber, accessor:@escaping Accessor, mutator:@escaping Mutator) {
        self._accessor = accessor
        self._mutator = mutator
        super.init(context: context, subscriber: subscriber)
    }
    
    public required init(context: ExecutionContextProtocol, subscriber: @escaping Subscriber) {
        fatalError("init(context:subscriber:) has not been implemented")
    }
    
    public func async(_ f: @escaping (T, Mutator) -> Void) {
        context.async {
            f(self._accessor(), self._mutator)
        }
    }
    
    public func sync(_ f:@escaping (Payload, Mutator)->Void) -> T {
        return context.sync {
            f(self._accessor(), self._mutator)
            return self._accessor()
        }
    }
}

//TODO: combine latest

public class ObservableValue<T> : MutableObservableProtocol {
    public typealias Payload = T
    //old, new
    public typealias ChangePayload = (Payload, Payload)
    
    //function passed for mutation
    public typealias Mutator = (Payload) -> Void
    
    public let dispatcher:EventDispatcher = EventDispatcher()
    public let context: ExecutionContextProtocol
    
    private var _var:T
    
    public init(_ value:T, context:ExecutionContextProtocol = ExecutionContext.current) {
        _var = value
        self.context = context
    }
    
    private func mutate(value:T) {
        let old = _var
        emit(.willChange, payload: (old, value))
        _var = value
        emit(.didChange, payload: (old, value))
    }
    
    public func on(_ groupedEvent: ObservableEventGroup<ChangePayload, ObservableWillChangeEvent<ChangePayload>>) -> SignalStream<ChangePayload> {
        return self.on(groupedEvent.event)
    }
    
    public func on(_ groupedEvent: ObservableEventGroup<ChangePayload, ObservableDidChangeEvent<ChangePayload>>) -> SignalStream<ChangePayload> {
        return self.on(groupedEvent.event)
    }
    
    private func emit<E : Event>(_ groupedEvent: ObservableEventGroup<ChangePayload, E>, payload:E.Payload) {
        self.emit(groupedEvent.event, payload: payload)
    }
    
    public func async(_ f:@escaping (Payload)->Void) {
        context.async {
            f(self._var)
        }
    }
    
    //current, mutator
    public func async(_ f:@escaping (Payload, Mutator)->Void) {
        context.async {
            f(self._var, self.mutate)
        }
    }
    
    public func sync(_ f:@escaping (Payload, Mutator)->Void = {_,_ in}) -> T {
        return context.sync {
            f(self._var, self.mutate)
            return self._var
        }
    }
}

extension MutableObservableProtocol {
    public func consume(payload: Payload) {
        async { _, mutator in
            mutator(payload)
        }
    }
}
