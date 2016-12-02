//===--- UIControl.swift ----------------------------------------------===//
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

private var controlDispatcherKey:Int = 401009

extension UIControl : EventEmitter {
    public var dispatcher:EventDispatcher {
        get {
            if let anyDispatch = objc_getAssociatedObject(self, &controlDispatcherKey) {
                return anyDispatch as! EventDispatcher
            }
            
            let dispatcher = EventDispatcher()
            objc_setAssociatedObject(self, &controlDispatcherKey, dispatcher, .OBJC_ASSOCIATION_RETAIN)
            return dispatcher
        }
    }
    
    private class UIEventSignalStream : SignalNode<UIEvent> {
        private static let selector:Selector = #selector(ActionProcessor.action(sender:forEvent:))
        
        private class ActionProcessor : NSObject {
            private unowned let _stream:UIEventSignalStream
            
            init(stream:UIEventSignalStream) {
                self._stream = stream
            }
            
            @objc func action(sender: UIControl, forEvent event: UIEvent) {
                _stream <= event
            }
        }
        
        private var _ap:ActionProcessor?
        private weak var _control:UIControl?
        private let _event:UIControlEvents
        
        init(control:UIControl, event:UIControlEvents) {
            _control = control
            _event = event
            
            super.init(context: control.context)
            
            _ap = ActionProcessor(stream: self)
            
            control.addTarget(_ap, action: UIEventSignalStream.selector, for: event)
        }
        
        deinit {
            _control?.removeTarget(_ap!, action: UIEventSignalStream.selector, for: _event)
        }
    }
    
    public func on(_ uiEvent:UIControlEvents) -> SignalStream<UIEvent> {
        return UIEventSignalStream(control: self, event: uiEvent)
    }
}
