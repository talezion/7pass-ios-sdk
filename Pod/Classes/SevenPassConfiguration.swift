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
        "development": "https://7pass.192.168.0.101.xip.io"
    ]
    
    public init(consumerKey: String, consumerSecret: String = "", callbackUri: String, environment: String = "production") {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackUri = callbackUri
        self.environment = environment
        self.host = self.hosts[environment]!
    }
  
    public typealias FailureHandler = (NSError) -> Void

    public func fetch(success success: () -> Void, failure: FailureHandler?) {
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

    private func fetchJSON(urlString: String, success: (NSDictionary) -> Void, failure: FailureHandler?) {
        let url = NSURL(string: urlString)

        let cache = try! Cache<NSDictionary>(name: "p7SsoDictionaries")
        
        cache.setObjectForKey("fetchJson|\(urlString)",
            cacheBlock: { cacheSuccess, cacheFailure in
                let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                    if let error = error {
                        cacheFailure(error)
                        
                        return
                    }
                    
                    let response = response as! NSHTTPURLResponse
                    
                    // Throw error when status code >= 400
                    if response.statusCode >= 400 {
                        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
                        let localizedDescription = "Server responded with HTTP Status: \(response.statusCode), Response: \(responseString)"
                        let userInfo: [NSObject : AnyObject] = [NSLocalizedDescriptionKey: localizedDescription]
                        let error = NSError(domain: NSURLErrorDomain, code: response.statusCode, userInfo: userInfo)
                        
                        cacheFailure(error)
                        
                        return
                    }
                   
                    // Parse JSON and cache result
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        
                        cacheSuccess(json, .Seconds(60 * 60 * 24 * 90)) // Cache for 90 days
                    } catch let error as NSError {
                        cacheFailure(error)
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
