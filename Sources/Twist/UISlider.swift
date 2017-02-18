//===--- UISlider.swift ----------------------------------------------===//
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

public enum UISliderValueChangedEvent : Event {
    public typealias Payload = Float
    case event
}

public struct UISliderEventGroup<E : Event> {
    internal let event:E
    
    private init(_ event:E) {
        self.event = event
    }
    
    public static var sliderValueChanged:UISliderEventGroup<UISliderValueChangedEvent> {
        return UISliderEventGroup<UISliderValueChangedEvent>(.event)
    }
}

public extension UISlider {
    public func on(_ groupedEvent: UISliderEventGroup<UISliderValueChangedEvent>) -> SignalStream<Float> {
        //TODO: change the underlying API to have tuple (Sender, Event)
        return self.on(.valueChanged).map {_ in self.value}
    }
}

public extension PropertyDescriptor where Component : UISlider {
    public static var value:MutablePropertyDescriptor<Component, MutableObservable<Float>> {
        get {
            return MutablePropertyDescriptor<Component, MutableObservable<Float>>(subscribe: { component, early in
                return component.on(.sliderValueChanged).map { value in
                    //TODO: make it somehow different
                    (value, value)
                }
                }, accessor: { component in
                    component.value
                }, mutator: { component, payload in
                    component.value = payload
            })
        }
    }
}
