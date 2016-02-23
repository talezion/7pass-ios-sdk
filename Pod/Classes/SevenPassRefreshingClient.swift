//
//  SevenPassRefreshingClient.swift
//  SevenPass
//
//  Created by Jan Votava on 29/01/16.
//
//

import OAuthSwift

public class SevenPassRefreshingClient: SevenPassClient {
    // MARK: Properties
    let sso: SevenPass
    var tokenSet: SevenPassTokenSet
    let tokenSetUpdatedCallback: TokenSetUpdated?

    // MARK: callback alias
    public typealias TokenSetUpdated = (tokenSet: SevenPassTokenSet) -> Void

    // MARK: init
    init(sso: SevenPass, baseUri: NSURL, tokenSet: SevenPassTokenSet, consumerSecret: String?, tokenSetUpdated: TokenSetUpdated? = nil) {
        guard let accessToken = tokenSet.accessToken?.token else { fatalError("accessToken is missing") }

        self.sso = sso
        self.tokenSet = tokenSet
        self.tokenSetUpdatedCallback = tokenSetUpdated

        super.init(baseUri: baseUri, accessToken: accessToken, consumerSecret: consumerSecret)
    }

    // MARK: methods
    public override func request(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String] = [:], success: SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        ensureFreshTokenSet(
            success: {
                super.request(url, method: method, parameters: parameters, headers: headers, success: success, failure: { error in
                    // Handle revoked access_tokens
                    if error.code == 401 {
                        self.refreshTokenSet(self.tokenSet,
                            success: {
                                super.request(url, method: method, parameters: parameters, headers: headers, success: success, failure: failure)
                            },
                            failure: failure
                        )
                    } else {
                        failure?(error: error)
                    }
                })
            },
            failure: failure
        )
    }

    func refreshTokenSet(tokenSet: SevenPassTokenSet, success: () -> Void, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if let refreshToken = tokenSet.refreshToken where !refreshToken.isExpired() {
            sso.authorize(refreshToken: refreshToken.token,
                success: { tokenSet in
                    self.tokenSet = tokenSet

                    if let accessToken = tokenSet.accessToken?.token {
                        self.accessToken = accessToken
                    }

                    self.tokenSetUpdatedCallback?(tokenSet: tokenSet)
                    success()
                },
                failure: { error in
                    failure?(error: error)
                }
            )
        } else if let failure = failure {
            let error = NSError(domain:SevenPassErrorDomain, code:0, userInfo:[NSLocalizedDescriptionKey: "Refresh token is expired"])

            failure(error: error)
        }
    }

    func ensureFreshTokenSet(success success: () -> Void, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if tokenSet.accessToken?.isExpired() == false {
            // AccessToken is fresh
            success()
        } else {
            refreshTokenSet(tokenSet, success: success, failure: failure)
        }
    }
}
