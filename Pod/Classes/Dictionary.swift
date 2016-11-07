//
//  Dictionary.swift
//  Pods
//
//  Created by Jan Votava on 28/10/2016.
//
//

extension Dictionary {
    mutating func update(_ other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

