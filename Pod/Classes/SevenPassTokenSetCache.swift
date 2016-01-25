//
//  SevenPassTokenSetCache.swift
//  SevenPass
//
//  Created by Jan Votava on 14/12/15.
//  Copyright © 2015 Jan Votava. All rights reserved.
//

import Locksmith

public struct SevenPassTokenSetCache: ReadableSecureStorable, CreateableSecureStorable, DeleteableSecureStorable, GenericPasswordSecureStorable {
    public let clientId: String
    public let environment: String
    public var tokenSet: SevenPassTokenSet?

    // Required by GenericPasswordSecureStorable
    public let service = "SevenPassTokenSet"
    public var account: String { return "\(clientId)|\(environment)" }
    
    public init(clientId: String, environment: String) {
        self.clientId = clientId
        self.environment = environment
    }

    public init(configuration: SevenPassConfiguration) {
        self.init(clientId: configuration.consumerKey, environment: configuration.environment)
    }

    // Required by CreateableSecureStorable
    public var data: [String: AnyObject] {
        guard let tokenSet = tokenSet else { fatalError("tokenSet is missing") }

        return [
            "token_set": tokenSet
        ]
    }

    public func save() {
        self.delete()
        
        try! self.createInSecureStore()
    }

    public func load() -> SevenPassTokenSet? {
        return readFromSecureStore()?.data?["token_set"] as? SevenPassTokenSet
    }
    
    public func delete() {
        if self.readFromSecureStore() != nil {
            try! self.deleteFromSecureStore()
        }
    }
}