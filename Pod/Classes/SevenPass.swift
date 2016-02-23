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

    var oauthswift: OAuth2Swift!

    public init(configuration: SevenPassConfiguration, urlHandler: SevenPassWebViewController? = nil) {
        self.configuration = configuration
        self.urlHandler = urlHandler ?? SevenPassWebViewController(urlString: configuration.callbackUri)
    }

    private func loadJwt(jwt: String, consumerKey: String? = nil) throws -> JWT {
        let jwt = try decode(jwt)

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

    public class func handleOpenURL(url: NSURL) {
        return OAuthSwift.handleOpenURL(url)
    }

    func baseUri(basePath: String) -> NSURL {
        return NSURL(string: "\(configuration.host)\(basePath)")!
    }

    public func accountClient(tokenSet: SevenPassTokenSet, tokenSetUpdated: SevenPassRefreshingClient.TokenSetUpdated? = nil) -> SevenPassRefreshingClient {
        return SevenPassRefreshingClient(sso: self, baseUri: baseUri("/api/accounts/"), tokenSet: tokenSet, consumerSecret: configuration.consumerSecret, tokenSetUpdated: tokenSetUpdated)
    }

    public func credentialsClient(tokenSet: SevenPassTokenSet) -> SevenPassClient {
        guard let accessToken = tokenSet.accessToken?.token else { fatalError("accessToken is missing") }

        return SevenPassClient(baseUri: baseUri("/api/client/"), accessToken: accessToken, consumerSecret: configuration.consumerSecret)
    }

    func initOauthSwift() {
        if self.oauthswift != nil {
            return
        }

        let config = self.configuration.config

        let oauthSwift = OAuth2Swift(
            consumerKey:    self.configuration.consumerKey,
            consumerSecret: self.configuration.consumerSecret,
            authorizeUrl:   config["authorization_endpoint"] as! String,
            accessTokenUrl: config["token_endpoint"] as! String
        )

        oauthSwift.authorize_url_handler = self.urlHandler
        self.oauthswift = oauthSwift
    }

    func loadResponse(parameters: NSDictionary, login: String = "") throws -> SevenPassTokenSet {
        let tokenSet = SevenPassTokenSet()

        if let accessToken = parameters["access_token"] as? String {
            var expiresIn: NSTimeInterval = 120 // Default expire to 2 minutes

            // Implicit flow
            if let expires = parameters["expires_in"] as? String { // Implicit flow
                expiresIn = NSTimeInterval(expires)! - NSTimeInterval(60)
            } else if let expires = parameters["expires_in"] as? Int { // Authorization code flow
                expiresIn = NSTimeInterval(expires) - NSTimeInterval(60)
            }

            tokenSet.accessToken = SevenPassToken(token: accessToken, expiresIn: expiresIn)
        }

        if let refreshToken = parameters["refresh_token"] as? String {
            let expiresIn = NSTimeInterval(90 * 24 * 60 * 60) - NSTimeInterval(60) // 90 days - 60s

            tokenSet.refreshToken = SevenPassToken(token: refreshToken, expiresIn: expiresIn)
        }

        if let idToken = parameters["id_token"] as? String {
            tokenSet.idToken = idToken
            let jwt = try self.loadJwt(idToken, consumerKey: self.configuration.consumerKey)
            tokenSet.idTokenDecoded = jwt.body
        }

        return tokenSet
    }

    public func authorize(var parameters parameters: Dictionary<String, String>, success: SevenPassTokenSet -> Void, failure: SevenPassConfiguration.FailureHandler) {
        configuration.fetch(
            success: { [unowned self] in
                self.initOauthSwift()

                let config = self.configuration.config

                parameters["client_id"] = self.configuration.consumerKey
                parameters["client_secret"] = self.configuration.consumerSecret

                let successHandler: OAuthSwiftHTTPRequest.SuccessHandler = { data, response in
                    let json: Dictionary<String, AnyObject>

                    do {
                        json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
                    } catch let error as NSError {
                        failure(error)

                        return
                    }

                    let tokenSet: SevenPassTokenSet

                    do {
                        tokenSet = try self.loadResponse(json)
                    } catch let error as NSError {
                        failure(error)

                        return
                    }

                    success(tokenSet)
                }

                self.oauthswift.client.request(config["token_endpoint"] as! String,
                    method: .POST,
                    parameters: parameters,
                    success: successHandler,
                    failure: failure
                )
            },
            failure: failure
        )
    }

    public func authorize(scopes scopes: Array<String>, var params: [String: String] = [String: String](), success: (tokenSet: SevenPassTokenSet) -> Void, failure: SevenPassConfiguration.FailureHandler) {
        configuration.fetch(
            success: { [unowned self] in
                self.initOauthSwift()

                params["nonce"] = OAuthSwiftCredential.generateNonce()

                if params["response_type"] == nil {
                    var responseType = "code"

                    // Implicit flow when secret is not present
                    if self.configuration.consumerSecret.isEmpty {
                        responseType = "id_token+token"
                    }

                    params["response_type"] = responseType
                }

                self.oauthswift.authorizeWithCallbackURL(
                    NSURL(string: self.configuration.callbackUri)!,
                    scope: scopes.joinWithSeparator("+"), state: "",
                    params: params,
                    success: { credential, response, parameters in
                        let tokenSet: SevenPassTokenSet

                        do {
                            tokenSet = try self.loadResponse(parameters)
                        } catch let error as NSError {
                            failure(error)

                            return
                        }

                        success(tokenSet: tokenSet)
                    },
                    failure: failure
                )
            },
            failure: failure
        )
    }

    public func authorize(login login: String, password: String, scopes: Array<String>, success: (tokenSet: SevenPassTokenSet) -> Void, failure: SevenPassConfiguration.FailureHandler) {
        authorize(
            parameters: [
                "grant_type": "password",
                "scope": scopes.joinWithSeparator(" "),

                "login": login,
                "password": password
            ],
            success: success,
            failure: failure
        )
    }

    public func authorize(refreshToken refreshToken: String, success: (tokenSet: SevenPassTokenSet) -> Void, failure: SevenPassConfiguration.FailureHandler) {
        authorize(
            parameters: [
                "grant_type": "refresh_token",

                "refresh_token": refreshToken
            ],
            success: success,
            failure: failure
        )
    }

    public func authorize(providerName providerName: String, accessToken: String, scopes: Array<String>, success: (tokenSet: SevenPassTokenSet) -> Void, failure: SevenPassConfiguration.FailureHandler) {
        authorize(
            parameters: [
                "grant_type": "social",
                "scope": scopes.joinWithSeparator(" "),

                "provider_name": providerName,
                "access_token": accessToken
            ],
            success: success,
            failure: failure
        )
    }

    public func autologin(autologinToken autologinToken: String, scopes: Array<String>, var params: [String: String] = [String: String](), success: (tokenSet: SevenPassTokenSet) -> Void, failure: SevenPassConfiguration.FailureHandler) {

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

    public func autologin(tokenSet: SevenPassTokenSet, scopes: Array<String>, rememberMe: Bool, params: [String: String] = [String: String](), success: (tokenSet: SevenPassTokenSet) -> Void, failure: SevenPassConfiguration.FailureHandler) {
        guard let accessToken = tokenSet.accessToken?.token else { fatalError("accessToken is missing") }
        guard let idToken = tokenSet.idToken else { fatalError("idToken is missing") }

        let payload: Dictionary<String, AnyObject> = [
            "access_token": accessToken,
            "id_token": idToken,
            "remember_me": rememberMe
        ]

        let autologinToken = encode(payload, algorithm: .HS256(configuration.consumerSecret))

        autologin(autologinToken: autologinToken, scopes: scopes, params: params, success: success, failure: failure)
    }

    public func destroyWebviewSession(success success: (() -> Void)? = nil, failure: SevenPassConfiguration.FailureHandler) {
        configuration.fetch(
            success: {
                let config = self.configuration.config
                let endSessionEndpoint = config["end_session_endpoint"] as! String

                self.urlHandler.destroySession(NSURL(string: endSessionEndpoint)!)
            },
            failure: failure
        )
    }
}

// MARK: SevenPass errors
public let SevenPassErrorDomain = "sevenpass.error"

