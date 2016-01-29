//
//  SevenPassClient.swift
//  SevenPass
//
//  Created by Jan Votava on 18/12/15.
//  Copyright © 2015 Jan Votava. All rights reserved.
//

import OAuthSwift
import CryptoSwift

public class SevenPassClient {
    public let consumerSecret: String?
    public var baseUri: NSURL = NSURL()
    private let oAuthSwiftClient: OAuthSwiftClient

    var accessToken: String {
        get {
            return oAuthSwiftClient.credential.oauth_token
        }
        set {
            oAuthSwiftClient.credential.oauth_token = newValue
        }
    }

    public typealias SuccessHandler = (json: Dictionary<String, AnyObject>, response: NSHTTPURLResponse) -> Void

    public init(consumerSecret: String?) {
        self.consumerSecret = consumerSecret
        
        self.oAuthSwiftClient = OAuthSwiftClient(consumerKey: "", consumerSecret: "")
        self.oAuthSwiftClient.credential.version = .OAuth2
    }

    var appsecretProof: String? {
        if let consumerSecret = self.consumerSecret {
            let authenticator = Authenticator.HMAC(key: Array(consumerSecret.utf8), variant: HMAC.Variant.sha256)

            return self.accessToken.authenticate(authenticator)
        } else {
            return nil
        }
    }

    // MARK: client methods
    public func get(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func post(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .POST, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func put(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .PUT, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func delete(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func patch(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func request(var url: String, method: OAuthSwiftHTTPRequest.Method, var parameters: [String: AnyObject] = [:], var headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        // Prepend base uri
        url = NSURL(string: url, relativeToURL: self.baseUri)!.absoluteString
        parameters["appsecret_proof"] = appsecretProof

        if headers["Content-Type"] == nil {
          headers["Content-Type"] = "application/json"
        }

        let successHandler: OAuthSwiftHTTPRequest.SuccessHandler = { data, response in
            let json: Dictionary<String, AnyObject>

            do {
                json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! Dictionary<String, AnyObject>
            } catch {
                failure?(error: error as NSError)

                return
            }

            success?(json: json, response: response)
        }

        return oAuthSwiftClient.request(url, method: method, parameters: parameters, headers: headers, success: successHandler, failure: failure)
    }
}
