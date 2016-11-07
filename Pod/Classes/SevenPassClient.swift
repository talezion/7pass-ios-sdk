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
    public let consumerKey: String
    public let consumerSecret: String?
    public var baseUri: URL
    private let oAuthSwiftClient: OAuthSwiftClient

    var accessToken: String {
        get {
            return oAuthSwiftClient.credential.oauthToken
        }
        set {
            oAuthSwiftClient.credential.oauthToken = newValue
        }
    }

    public typealias SuccessHandler = (_ json: Dictionary<String, AnyObject>, _ response: HTTPURLResponse) -> Void

    public init(baseUri: URL, accessToken: String, consumerKey: String, consumerSecret: String?) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        
        self.oAuthSwiftClient = OAuthSwiftClient(consumerKey: "", consumerSecret: "")
        self.oAuthSwiftClient.credential.version = .oauth2

        self.baseUri = baseUri
        self.accessToken = accessToken
    }

    var appsecretProof: String? {
        if let consumerSecret = self.consumerSecret {
            do {
                let hmac = try HMAC(key: Array(consumerSecret.utf8), variant: .sha256).authenticate(Array(self.accessToken.utf8))
                return hmac.toHexString()
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }

    // MARK: client methods
    public func get(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func post(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        self.request(urlString, method: .POST, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func put(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        self.request(urlString, method: .PUT, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func delete(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        self.request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func patch(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        self.request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    // TODO: implement OAuthSwiftRequestHandle?
    public func request(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        // Prepend base uri
        var headers = headers
        let url = URL(string: urlString, relativeTo: self.baseUri)!.absoluteString
        var parameters = parameters
        parameters["appsecret_proof"] = appsecretProof

        headers["X-Service-Id"] = self.consumerKey

        if headers["Content-Type"] == nil {
          headers["Content-Type"] = "application/json"
        }

        let successHandler: OAuthSwiftHTTPRequest.SuccessHandler = { data, response in
            let json: Dictionary<String, AnyObject>

            do {
                json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String, AnyObject>
            } catch let error {
                failure?(error as NSError)

                return
            }

            success?(json, response)
        }

        oAuthSwiftClient.request(url, method: method, parameters: parameters, headers: headers, success: successHandler, failure: SevenPassError.handler(success: nil, failure: failure))
    }
}
