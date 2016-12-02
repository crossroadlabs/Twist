//===--- UITextField.swift ----------------------------------------------===//
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
import UIKit

import Event

public enum UITextFieldTextEvent : Event {
    public typealias Payload = String
    case event
}

public struct UITextFieldEventGroup<E : Event> {
    internal let event:E
    
    private init(_ event:E) {
        self.event = event
    }
    
    public static var textChanged:UITextFieldEventGroup<UITextFieldTextEvent> {
        return UITextFieldEventGroup<UITextFieldTextEvent>(.event)
    }
}

public extension UITextField {
    public func on(_ groupedEvent: UITextFieldEventGroup<UITextFieldTextEvent>) -> SignalStream<String> {
        return NotificationCenter.default.for(object: self).on(.UITextFieldTextDidChange).map { notification in
            (notification.object! as! UITextField).text!
        }
    }
}

public extension PropertyDescriptor where Component : UITextField {
    public static var text:MutablePropertyDescriptor<Component, MutableObservable<String>> {
        get {
            return MutablePropertyDescriptor<Component, MutableObservable<String>>(subscribe: { component, early in
                return component.on(.textChanged).map { text in
                    //TODO: make it somehow different
                    (text, text)
                }
                }, accessor: { component in
                    component.text ?? ""
                }, mutator: { component, payload in
                    component.text = payload
            })
        }
    }
}
