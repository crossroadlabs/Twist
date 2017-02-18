//
//  ViewController.swift
//  TwistExample
//
//  Created by Daniel Leping on 29/11/2016.
//  Copyright © 2016 Crossroad Labs s.r.o. All rights reserved.
//

import UIKit

import Twist
import Event

class ViewController: UIViewController {
    @IBOutlet weak var button:UIButton?
    @IBOutlet weak var slider:UISlider?
    @IBOutlet weak var text1:UITextField?
    @IBOutlet weak var text2:UITextField?
    
    var bucket = DisposalBucket()

    override func viewDidLoad() {
        let b1 = ObservableValue(1)
        let b2 = ObservableValue(2)
        
        b1.bind(to: b2) => bucket
        
        b1.react { b in
            print("!!!!blabla!!!", b)
        } => bucket
        
        b2.react { b in
            print("!!!!mmmmmm!!!", b)
        } => bucket
        
        b1 <= 3
        
        text1?.alpha = 0
        text2?.isHidden = true
        UIView.animate(duration: 4) {
            self.text1?.alpha = 1
        }.onSuccess { completed in
            self.text2?.isHidden = false
        }
        
        slider?.property(.value).stream.map {
            CGFloat($0)
            }.pour(to: button!, on: .alpha) => bucket//pour(to: button!.property(.alpha)) => bucket
        
        let hidden = text2!.property(.hidden)
        
        hidden.pour(to: self.button!.property(.hidden)) => bucket
        //hidden.bind(to: self.button!, on: .hidden) => bucket
        
        hidden.react { hidden in
            self.button?.isHidden = hidden
            } => bucket
        
        let node = ObservableValue("OK") //SignalNode<String>()
        bucket <= node.bind(to: text1!, on: .text)
        node.debounce(timeout: 0.5).pour(to: text2!, on: .text) => bucket
        
        //stream.pour(to: text2!, on: .text) => bucket
        //endpoint.subscribe(to: text2!, on: .text) => bucket
        
        let ss:Int? = nil
        
        ss.map { int in
            String(int) + "lala"
            } => node
        
        /*bucket <= text1?.on(.textChanged).react { text in
         self.text2?.isHidden = text == "hide"
         }*/
        
        bucket <= text1?.on(.textChanged).map { text in
            text == "hide"
            }.pour(to: hidden)
        
        button?.on(.tap).map {"Hi! Motherfucker!"}.pour(to: node) => bucket
        
        let sss = node//ObservableValue("OK")
        sss.react { sss in
            print("!!!REACT:", sss)
            } => bucket
        
        sss.on(.didChange).react { old, new in
            print("!!!DID:", old, new)
            } => bucket
        
        sss.on(.willChange).react { old, new in
            print("!!!WILL:", old, new)
            } => bucket
        
        sss.mutate { sss, mutate in
            mutate(sss + "123")
        }
        
        
        //var some:SignalNode
        //some.pour(to: text1, .text)
        
        text1?.property(.text).react { text in
            print("$$$$$$$$$$$$$$$$$$$$$$$$$$$", text)
        } => bucket
        
        // Do any additional setup after loading the view, typically from a nib.
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

