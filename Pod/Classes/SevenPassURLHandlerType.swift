//
//  SevenPassURLHandlerType.swift
//  SevenPass
//
//  Created by Jan Votava on 29/01/16.
//
//

import OAuthSwift

@objc public protocol SevenPassURLHandlerType: OAuthSwiftURLHandlerType {
    func destroySession(logoutUrl: NSURL)
}