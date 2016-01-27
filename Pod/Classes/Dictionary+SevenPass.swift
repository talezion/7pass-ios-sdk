//
//  Dictionary+SevenPass.swift
//  Pods
//
//  Created by Jan Votava on 26/01/16.
//
//

import Foundation

extension Dictionary {
    func map<K: Hashable, V> (transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
        var results: Dictionary<K, V> = [:]
        for k in self.keys {
            if let value = self[ k ] {
                let (u, w) = transform(k, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
}