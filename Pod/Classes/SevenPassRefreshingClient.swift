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
    public typealias TokenSetUpdated = (_ tokenSet: SevenPassTokenSet) -> Void

    // MARK: init
    init(sso: SevenPass, baseUri: URL, tokenSet: SevenPassTokenSet, consumerKey: String, consumerSecret: String?, tokenSetUpdated: TokenSetUpdated? = nil) {
        guard let accessToken = tokenSet.accessToken?.token else { fatalError("accessToken is missing") }

        self.sso = sso
        self.tokenSet = tokenSet
        self.tokenSetUpdatedCallback = tokenSetUpdated

        super.init(baseUri: baseUri, accessToken: accessToken, consumerKey: consumerKey, consumerSecret: consumerSecret)
    }

    // MARK: methods
    public override func request(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers = [:], success: SuccessHandler?, failure: SevenPassError.Handler?) {
        ensureFreshTokenSet(
            success: {
                super.request(urlString, method: method, parameters: parameters, headers: headers, success: success, failure: { error in
                    // Handle revoked access_tokens
                    if error._code == 401 {
                        self.refreshTokenSet(self.tokenSet,
                            success: {
                                super.request(urlString, method: method, parameters: parameters, headers: headers, success: success, failure: failure)
                            },
                            failure: failure
                        )
                    } else {
                        failure?(error)
                    }
                })
            },
            failure: failure
        )
    }

    func refreshTokenSet(_ tokenSet: SevenPassTokenSet, success: @escaping () -> Void, failure: SevenPassError.Handler?) {
        if let refreshToken = tokenSet.refreshToken , !refreshToken.isExpired() {
            sso.authorize(refreshToken: refreshToken.token,
                success: { tokenSet in
                    self.tokenSet = tokenSet

                    if let accessToken = tokenSet.accessToken?.token {
                        self.accessToken = accessToken
                    }

                    self.tokenSetUpdatedCallback?(tokenSet)
                    success()
                },
                failure: { error in
                    failure?(error)
                }
            )
        } else {
            let error = NSError(domain:SevenPassError.Domain, code:0, userInfo:[NSLocalizedDescriptionKey: "Refresh token is expired"])
            failure?(error)
        }
    }

    func ensureFreshTokenSet(success: @escaping () -> Void, failure: SevenPassError.Handler?) {
        if tokenSet.accessToken?.isExpired() == false {
            // AccessToken is fresh
            success()
        } else {
            refreshTokenSet(tokenSet, success: success, failure: failure)
        }
    }
}
