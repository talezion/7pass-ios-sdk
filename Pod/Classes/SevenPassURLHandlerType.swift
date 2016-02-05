//
//  SevenPassURLHandlerType.swift
//  SevenPass
//
//  Created by Jan Votava on 29/01/16.
//
//

import OAuthSwift_p7s1

@objc public protocol SevenPassURLHandlerType: OAuthSwiftURLHandlerType {
    func destroySession(logoutUrl: NSURL)
}