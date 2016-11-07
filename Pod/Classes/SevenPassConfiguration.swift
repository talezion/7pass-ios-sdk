//
//  SevenPassConfiguration.swift
//  SevenPass
//
//  Created by Jan Votava on 16/12/15.
//  Copyright © 2015 Jan Votava. All rights reserved.
//

import Foundation
import OAuthSwift
import AwesomeCache

public class SevenPassConfiguration {
    public let consumerKey: String
    public let consumerSecret: String
    public let callbackUri: String
    public let environment: String

    var config: NSDictionary = NSDictionary()
    var jwksConfig: NSDictionary = NSDictionary()
    var host: String

    let hosts: [String: String] = [
        "production": "https://sso.7pass.de",
        "qa": "https://sso.qa.7pass.ctf.prosiebensat1.com",
        "development": "https://7pass.dev"
    ]
    
    public init(consumerKey: String, consumerSecret: String = "", callbackUri: String, environment: String = "production") {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackUri = callbackUri
        self.environment = environment
        self.host = self.hosts[environment]!
    }
  
    public func fetch(success: @escaping () -> Void, failure: SevenPassError.Handler?) {
        self.fetchJSON(
            "\(self.host)/.well-known/openid-configuration",
            success: { (configuration) in
                self.config = configuration
                success()

//                // NOTE: no need to fetch keys, because we're not validating RS256 signatures now
//                let jwksUri = configuration["jwks_uri"] as! String
//                
//                self.fetchJSON(
//                    jwksUri,
//                    success: { (jwksConfig) in
//                        self.jwksConfig = jwksConfig
//                        success()
//                    },
//                    failure: failure
//                )

            },
            failure: failure
        )
    }

    private func fetchJSON(_ urlString: String, success: @escaping (NSDictionary) -> Void, failure: SevenPassError.Handler?) {
        let url = URL(string: urlString)

        let cache = try! Cache<NSDictionary>(name: "p7SsoDictionaries")

        cache.setObject(forKey: "fetchJson|\(urlString)",
            cacheBlock: { cacheSuccess, cacheFailure in
                let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
                    if let error = error {
                        cacheFailure(error as NSError)
                        
                        return
                    }

                    let response = response as! HTTPURLResponse
                    
                    // Throw error when status code >= 400
                    if response.statusCode >= 400 {
                        let responseString = String(data: data!, encoding: String.Encoding.utf8)
                        let localizedDescription = "Server responded with HTTP Status: \(response.statusCode), Response: \(responseString)"
                        let userInfo: [String : Any] = [NSLocalizedDescriptionKey: localizedDescription]
                        let error = NSError(domain: NSURLErrorDomain, code: response.statusCode, userInfo: userInfo)
                        
                        cacheFailure(error)
                        
                        return
                    }
                   
                    // Parse JSON and cache result
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary

                        cacheSuccess(json, .seconds(60 * 60 * 24 * 90)) // Cache for 90 days
                    } catch let error {
                        cacheFailure(error as NSError)
                    }
                }
                
                task.resume()
            },
            completion: { object, isLoadedFromCache, error in
                if let error = error {
                    failure?(error)
                } else {
                    success(object!)
                }
        })
    }
}
