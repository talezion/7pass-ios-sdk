//
//  SsoManager.swift
//  SevenPass
//
//  Created by Jan Votava on 08/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import SevenPass

class SsoManager {
    static let sharedInstance = SsoManager()

    let sso: SevenPass

    init() {
        let configuration = SevenPassConfiguration(
            consumerKey: "56a0982fcd8fb606d000b233",
            consumerSecret: "2e7b77f99be28d80a60e9a2d2c664835ef2e02c05bf929f60450c87c15a59992",
            callbackUri: "oauthtest://oauth-callback",
            environment: "qa"
        )

        self.sso = SevenPass(configuration: configuration)
    }
}
