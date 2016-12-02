//===--- UIView.swift ----------------------------------------------===//
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

import Boilerplate
import ExecutionContext
import Future

extension UIView : ExecutionContextTenantProtocol {
    public var context: ExecutionContextProtocol {
        get {
            return ExecutionContext.main
        }
    }
}

public extension UIView {
    public class func animate(duration: Timeout, animation: @escaping () -> Void) -> Future<Bool> {
        let promise = Promise<Bool>()
        self.animate(withDuration: duration.timeInterval, animations: animation) { finished in
            try! promise.success(value: finished)
        }
        return promise.future
    }
    
    public class func animate(duration: Timeout, delay: Timeout, options: UIViewAnimationOptions = [], animation: @escaping () -> Void) -> Future<Bool> {
        let promise = Promise<Bool>()
        self.animate(withDuration: duration.timeInterval, delay: delay.timeInterval, options: options, animations: animation) { finished in
            try! promise.success(value: finished)
        }
        return promise.future
    }
}

public extension PropertyDescriptor where Component : UIView {
    public static var hidden:MutablePropertyDescriptor<Component, MutableObservable<Bool>> {
        get {
            return NSPropertyDescriptor(name: #keyPath(UIView.hidden))
        }
    }
    
    public static var alpha:MutablePropertyDescriptor<Component, MutableObservable<CGFloat>> {
        get {
            return NSPropertyDescriptor(name: #keyPath(UIView.alpha))
        }
    }
}
