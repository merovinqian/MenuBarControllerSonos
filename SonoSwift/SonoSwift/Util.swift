//
//  Util.swift
//  SonoSwift
//
//  Created by Alexander Heinrich on 13.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

internal func dPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        print(items, separator: separator, terminator: terminator)
    #endif
}

infix operator ~~
extension String {
    
    func formatted(_ arguments: CVarArg) -> String {
        return String.init(format: self.description, arguments)
    }
    
    static func ~~(lhs: String, rhs: CVarArg) -> String {
        return lhs.formatted(rhs)
    }
}
