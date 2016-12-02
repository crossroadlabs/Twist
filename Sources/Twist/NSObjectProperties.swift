//===--- NSObjectProperties.swift ----------------------------------------------===//
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

private class KVOProcessor<T> : NSObject {
    private unowned let _stream:KVOSignalStream<T>
    
    init(stream:KVOSignalStream<T>) {
        self._stream = stream
    }
    
    @objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let old = change?[.oldKey].flatMap { val in
            val as? T
        }
        
        let new = change?[.newKey].flatMap { val in
            val as? T
        }
        
        _stream <= (old!, new!)
    }
}

private class KVOSignalStream<T> : SignalNode<(T, T)> {
    private var _ap:KVOProcessor<T>?
    private weak var _object:NSObject?
    private let _property:String
    
    //TODO: handle early, fuck
    init(context:ExecutionContextProtocol, object:NSObject, property:String, early:Bool) {
        _object = object
        _property = property
        
        //TODO: should not be main
        super.init(context: context)
        
        _ap = KVOProcessor(stream: self)
        
        object.addObserver(_ap!, forKeyPath: property, options: [.new, .old], context: nil)
    }
    
    deinit {
        _object?.removeObserver(_ap!, forKeyPath: _property)
    }
}

public class NSPropertyDescriptor<Component: ExecutionContextTenantProtocol, T> : MutablePropertyDescriptor<Component, MutableObservable<T>> where Component : NSObject {
    public init(name:String) {
        super.init(subscribe: { component, early in
            return KVOSignalStream(context: component.context, object: component, property: name, early: early)
            }, accessor: { component in
                return component.value(forKey: name).flatMap { value in
                    value as? T
                    }!
            }, mutator: { component, value in
                component.setValue(value, forKey: name)
        })
    }
}

public extension NSObjectProtocol where Self : NSObject, Self : ExecutionContextTenantProtocol {
    public func property<T>(name: String, type: T.Type) -> MutableObservable<T> {
        let context = self.context
        return MutableObservable(context: context, subscriber: { early in
            return KVOSignalStream(context: context, object: self, property: name, early: early)
            }, accessor: {
                return self.value(forKey: name).flatMap { value in
                    value as? T
                    }!
            }, mutator: { value in
                self.setValue(value, forKey: name)
        })
    }
    
    public func p<T>(name: String, type: T.Type) -> MutableObservable<T> {
        return property(name: name, type: type)
    }
}

public extension NSObjectProtocol where Self : ExecutionContextTenantProtocol {
    public func property<Observable : ParametrizableObservableProtocol>(_ pd:PropertyDescriptor<Self, Observable>) -> Observable {
        return pd.makeProperty(for: self)
    }
    
    public func p<Observable : ParametrizableObservableProtocol>(_ pd:PropertyDescriptor<Self, Observable>) -> Observable {
        return pd.makeProperty(for: self)
    }
}
