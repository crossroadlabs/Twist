//===--- PropertyDescriptor.swift ----------------------------------------------===//
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

open class PropertyDescriptor<Component : ExecutionContextTenantProtocol, Observable : ParametrizableObservableProtocol> {
    public typealias Payload = Observable.Payload
    public typealias ChangePayload = Observable.ChangePayload
    public typealias Subscribe = (Component, Bool) -> SignalStream<ChangePayload>
    
    fileprivate let _subscribe:Subscribe
    
    public init(subscribe:@escaping Subscribe) {
        _subscribe = subscribe
    }
    
    public func makeProperty(for component: Component) -> Observable {
        return Observable(context: component.context) { early in
            return self._subscribe(component, early)
        }
    }
}

open class MutablePropertyDescriptor<Component : ExecutionContextTenantProtocol, Observable : ParametrizableMutableObservableProtocol> : PropertyDescriptor<Component, Observable> {
    public typealias Accessor = (Component) -> Payload
    public typealias Mutator = (Component, Payload) -> Void
    
    private let _accessor:Accessor
    private let _mutator:Mutator
    
    public init(subscribe:@escaping Subscribe, accessor:@escaping Accessor, mutator:@escaping Mutator) {
        _accessor = accessor
        _mutator = mutator
        super.init(subscribe: subscribe)
    }
    
    public override func makeProperty(for component: Component) -> Observable {
        return Observable(context: component.context, subscriber: { early in
            return self._subscribe(component, early)
            }, accessor: {
                return self._accessor(component)
            }, mutator: { _, payload in
                return self._mutator(component, payload)
        })
    }
}
