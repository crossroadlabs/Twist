//===--- NSNotificationCenter.swift ----------------------------------------------===//
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

import Boilerplate
import Event

extension NotificationCenter : SignatureProvider {
}

public struct NotificationObject {
    private let _center:NotificationCenter
    private let _object:Any?
    
    fileprivate init(center:NotificationCenter, object:Any?) {
        _center = center
        _object = object
    }
    
    public func on(_ name: Notification.Name) -> SignalStream<Notification> {
        let sig:Set<Int> = [_center.signature]
        
        let node = SignalNode<Notification>()
        //TODO: fix leak
        let _ = _center.addObserver(forName: name, object: _object, queue: nil) { notification in
            node.signal(signature: sig, payload: notification)
        }
        return node
    }
}

public extension NotificationCenter {
    public func `for`(object: Any?) -> NotificationObject {
        return NotificationObject(center: self, object: object)
    }
    
    public func on(_ name: Notification.Name) -> SignalStream<Notification> {
        return self.for(object: nil).on(name)
    }
}
