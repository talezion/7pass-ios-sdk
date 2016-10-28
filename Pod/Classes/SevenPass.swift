//
//  SevenPass.swift
//  SevenPass
//
//  Created by Jan Votava on 15/12/15.
//  Copyright © 2015 Jan Votava. All rights reserved.
//

import OAuthSwift
import JWTDecode
import JWT

public let OAuthJWTErrorDomain = "OAuthJWTErrorDomain"

public class SevenPass: NSObject {
    public let configuration: SevenPassConfiguration
    public let urlHandler: SevenPassURLHandlerType

    var oauthSwiftCache: OAuth2Swift?

    public init(configuration: SevenPassConfiguration, urlHandler: SevenPassWebViewController? = nil) {
        self.configuration = configuration
        self.urlHandler = urlHandler ?? SevenPassWebViewController(urlString: configuration.callbackUri)
    }

    private func loadJwt(_ jwt: String, consumerKey: String? = nil) throws -> JWT {
        let jwt = try decode(jwt: jwt)

        guard !jwt.expired else {
            let error = NSError(domain:OAuthJWTErrorDomain, code:0, userInfo:[NSLocalizedDescriptionKey: "Token is expired"])

            throw error
        }

        if let consumerKey = consumerKey {
            guard jwt.audience!.contains(consumerKey) else {
                let error = NSError(domain:OAuthJWTErrorDomain, code:0, userInfo:[NSLocalizedDescriptionKey: "Token has invalid audience"])

                throw error
            }
        }

        return jwt
    }

    public class func handleOpenURL(_ url: URL) {
        return OAuthSwift.handle(url: url)
    }

    func baseUri(_ basePath: String) -> URL {
        return URL(string: "\(configuration.host)\(basePath)")!
    }

    public func accountClient(_ tokenSet: SevenPassTokenSet, tokenSetUpdated: SevenPassRefreshingClient.TokenSetUpdated? = nil) -> SevenPassRefreshingClient {
        return SevenPassRefreshingClient(sso: self, baseUri: baseUri("/api/accounts/"), tokenSet: tokenSet, consumerKey: configuration.consumerKey, consumerSecret: configuration.consumerSecret, tokenSetUpdated: tokenSetUpdated)
    }

    public func credentialsClient(_ tokenSet: SevenPassTokenSet) -> SevenPassClient {
        guard let accessToken = tokenSet.accessToken?.token else { fatalError("accessToken is missing") }

        return SevenPassClient(baseUri: baseUri("/api/client/"), accessToken: accessToken, consumerKey: configuration.consumerKey, consumerSecret: configuration.consumerSecret)
    }

    func oauthSwift() -> OAuth2Swift {
        if let cached = self.oauthSwiftCache {
            return cached
        }

        let config = self.configuration.config

        let oauthSwift = OAuth2Swift(
            consumerKey:    self.configuration.consumerKey,
            consumerSecret: self.configuration.consumerSecret,
            authorizeUrl:   config["authorization_endpoint"] as! String,
            accessTokenUrl: config["token_endpoint"] as! String,
            responseType: ""
        )

        oauthSwift.authorizeURLHandler = self.urlHandler
        self.oauthSwiftCache = oauthSwift

        return oauthSwift
    }

    func loadResponse(_ parameters: Dictionary<String, Any>, login: String = "") throws -> SevenPassTokenSet {
        let tokenSet = SevenPassTokenSet()

        if let accessToken = parameters["access_token"] as? String {
            var expiresIn: TimeInterval = 120 // Default expire to 2 minutes

            // Implicit flow
            if let expires = parameters["expires_in"] as? String { // Implicit flow
                expiresIn = TimeInterval(expires)! - TimeInterval(60)
            } else if let expires = parameters["expires_in"] as? Int { // Authorization code flow
                expiresIn = TimeInterval(expires) - TimeInterval(60)
            }

            tokenSet.accessToken = SevenPassToken(token: accessToken, expiresIn: expiresIn)
        }

        if let refreshToken = parameters["refresh_token"] as? String {
            let expiresIn = TimeInterval(90 * 24 * 60 * 60) - TimeInterval(60) // 90 days - 60s

            tokenSet.refreshToken = SevenPassToken(token: refreshToken, expiresIn: expiresIn)
        }

        if let idToken = parameters["id_token"] as? String {
            tokenSet.idToken = idToken
            let jwt = try self.loadJwt(idToken, consumerKey: self.configuration.consumerKey)
            tokenSet.idTokenDecoded = jwt.body
        }

        return tokenSet
    }

    public func authorize(parameters: Dictionary<String, String>, success: @escaping (SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {
        var parameters = parameters
        configuration.fetch(
            success: { [unowned self] in
                let config = self.configuration.config

                parameters["client_id"] = self.configuration.consumerKey
                parameters["client_secret"] = self.configuration.consumerSecret

                let successHandler: OAuthSwiftHTTPRequest.SuccessHandler = { data, response in
                    let json: Dictionary<String, AnyObject>

                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                    } catch let error {
                        failure(error as NSError)

                        return
                    }

                    let tokenSet: SevenPassTokenSet

                    do {
                        tokenSet = try self.loadResponse(json)
                    } catch let error {
                        failure(error as NSError)

                        return
                    }

                    success(tokenSet)
                }

                self.oauthSwift().client.request(config["token_endpoint"] as! String,
                    method: .POST,
                    parameters: parameters,
                    headers: ["X-Service-Id": self.configuration.consumerKey],
                    success: successHandler,
                    failure: SevenPassError.handler(success: success, failure: failure)
                )
            },
            failure: failure
        )
    }

    public func authorize(scopes: Array<String>, params: OAuthSwift.Parameters = [:], success: @escaping (_ tokenSet: SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {
        var params = params
        configuration.fetch(
            success: { [unowned self] in
                params["nonce"] = OAuthSwiftCredential.generateNonce()

                if params["response_type"] == nil {
                    var responseType = "code"

                    // Implicit flow when secret is not present
                    if self.configuration.consumerSecret.isEmpty {
                        responseType = "id_token+token"
                    }

                    params["response_type"] = responseType
                }

                self.oauthSwift().authorize(
                    withCallbackURL: URL(string: self.configuration.callbackUri)!,
                    scope: scopes.joined(separator: "+"),
                    state: "ios",
                    parameters: params,
                    success: { credential, response, parameters in
                        let tokenSet: SevenPassTokenSet

                        do {
                            tokenSet = try self.loadResponse(parameters)
                        } catch let error {
                            failure(error as NSError)

                            return
                        }

                        success(tokenSet)
                    },
                    failure: SevenPassError.handler(success: success, failure: failure)
                )
            },
            failure: failure
        )
    }

    public func authorize(login: String, password: String, scopes: Array<String>, success: @escaping (_ tokenSet: SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {
        authorize(
            parameters: [
                "grant_type": "password",
                "scope": scopes.joined(separator: " "),

                "login": login,
                "password": password
            ],
            success: success,
            failure: failure
        )
    }

    public func authorize(refreshToken: String, success: @escaping (_ tokenSet: SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {
        authorize(
            parameters: [
                "grant_type": "refresh_token",

                "refresh_token": refreshToken
            ],
            success: success,
            failure: failure
        )
    }

    public func authorize(providerName: String, accessToken: String, scopes: Array<String>, success: @escaping (_ tokenSet: SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {
        authorize(
            parameters: [
                "grant_type": "social",
                "scope": scopes.joined(separator: " "),

                "provider_name": providerName,
                "access_token": accessToken
            ],
            success: success,
            failure: failure
        )
    }

    public func autologin(autologinToken: String, scopes: Array<String>, params: [String: String] = [String: String](), success: @escaping (_ tokenSet: SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {

        var params = params
        params["autologin"] = autologinToken

        if params["response_type"] == nil {
            params["response_type"] = "none"
        }

        authorize(
            scopes: scopes,
            params: params,
            success: success,
            failure: failure
        )
    }

    public func autologin(_ tokenSet: SevenPassTokenSet, scopes: Array<String>, rememberMe: Bool, params: [String: String] = [String: String](), success: @escaping (_ tokenSet: SevenPassTokenSet) -> Void, failure: @escaping SevenPassError.Handler) {
        guard let accessToken = tokenSet.accessToken?.token else { fatalError("accessToken is missing") }
        guard let idToken = tokenSet.idToken else { fatalError("idToken is missing") }

        let payload: Dictionary<String, Any> = [
            "access_token": accessToken,
            "id_token": idToken,
            "remember_me": rememberMe
        ]

        let autologinToken = encode(payload, algorithm: .hs256(configuration.consumerSecret.data(using: .utf8)!))

        autologin(autologinToken: autologinToken, scopes: scopes, params: params, success: success, failure: failure)
    }

    public func destroyWebviewSession(success: (() -> Void)? = nil, failure: @escaping SevenPassError.Handler) {
        configuration.fetch(
            success: {
                let config = self.configuration.config
                let endSessionEndpoint = config["end_session_endpoint"] as! String

                self.urlHandler.destroySession(logoutUrl: URL(string: endSessionEndpoint)!)
            },
            failure: failure
        )
    }
}
