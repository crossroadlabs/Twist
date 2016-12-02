//===--- ObservableSignals.swift ----------------------------------------------===//
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

public extension SignalNodeProtocol {
    public func bind<Component : ExecutionContextTenantProtocol, Observable : ParametrizableMutableObservableProtocol>(to component: Component, on pd: PropertyDescriptor<Component, Observable>) -> Off where Observable.Payload == Payload {
        let prop = pd.makeProperty(for: component)
        
        let forthOff = self.pour(to: prop)
        let backOff = prop.pour(to: self)
        
        return {
            forthOff()
            backOff()
        }
    }
}

public extension SignalStreamProtocol {
    public func pour<Component : ExecutionContextTenantProtocol, Observable : ParametrizableMutableObservableProtocol>(to component: Component, on pd: PropertyDescriptor<Component, Observable>) -> Off where Observable.Payload == Payload {
        let prop = pd.makeProperty(for: component)
        
        return self.pour(to: prop)
    }
}

public extension SignalEndpoint {
    public func subscribe<Component : ExecutionContextTenantProtocol, Observable : ParametrizableObservableProtocol>(to component: Component, on pd: PropertyDescriptor<Component, Observable>) -> Off where Observable.Payload == Payload {
        return pd.makeProperty(for: component).pour(to: self)
    }
}
