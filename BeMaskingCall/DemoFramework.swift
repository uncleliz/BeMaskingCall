//
//  DemoFramework.swift
//  BeMaskingCall
//
//  Created by manh.le on 5/21/19.
//  Copyright © 2019 manh.le. All rights reserved.
//

import Foundation

public class DemoFramework: NSObject
{
    private override init() {
        super.init()
    }
    public class func yourName(name: String)
    {
        consolLog(name: name)
    }
    class func consolLog(name: String) {
        print("******************")
        print("Welcome \(name)!!")
        print("*******************")
    }
}
