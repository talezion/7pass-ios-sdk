//
//  SevenPassError.swift
//  Pods
//
//  Created by Jan Votava on 28/10/2016.
//
//

public class SevenPassError {
    public static let Domain = "sevenpass.error"

    // MARK: SevenPass errors
    public typealias Handler = (NSError) -> Void
    public typealias ErrorTypeHandler = (CustomNSError) -> Void

    static public func handler(success: ((_ tokenSet: SevenPassTokenSet) -> Void)?, failure: Handler?) -> ErrorTypeHandler {
        return { error in
            if error.errorUserInfo["message"] as? String == "No access_token, no code and no error provided by server" {
                success?(SevenPassTokenSet())
            } else if let error = error.errorUserInfo["error"] as? NSError {
                if let responseBody = error.userInfo["Response-Body"] as? String {
                    let responseData = responseBody.data(using: String.Encoding.utf8)!

                    // Base userInfo on parsed JSON error message/description
                    var userInfo: [NSObject : Any]

                    do {
                        userInfo = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.mutableContainers) as! [NSObject: Any]
                    } catch {
                        userInfo = [:]
                    }

                    userInfo.update(error.userInfo as [NSObject: Any])

                    let errorWithResponse = NSError(domain: SevenPassError.Domain, code: error.code, userInfo: userInfo)
                    failure?(errorWithResponse)
                } else {
                    failure?(error)
                }
            } else {
                failure?(error as NSError)
            }
        }
    }
}
