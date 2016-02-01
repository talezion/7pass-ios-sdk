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
                // TODO: Handle access token expired errors
                super.request(url, method: method, parameters: parameters, headers: headers, success: success, failure: failure)
            },
            failure: failure
        )
    }

    func ensureFreshTokenSet(success success: () -> Void, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if tokenSet.accessToken?.isExpired() == true {
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
            } else {
                if let failure = failure {
                    let error = NSError(domain:SevenPassErrorDomain, code:0, userInfo:[NSLocalizedDescriptionKey: "Refresh token is expired"])

                    failure(error: error)
                }
            }
        } else {
            // AccessToken is fresh
            success()
        }
    }
}
