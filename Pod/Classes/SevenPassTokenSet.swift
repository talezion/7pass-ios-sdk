//
//  SevenPassTokenSet.swift
//  SevenPass
//
//  Created by Jan Votava on 13/01/16.
//
//

public class SevenPassTokenSet: NSObject, NSCoding {
    public var accessToken: SevenPassToken?
    public var refreshToken: SevenPassToken?
    public var idToken: String?
    public var idTokenDecoded: Dictionary<String, Any>?

    public var email: String? {
        return idTokenDecoded?["email"] as? String
    }

    override init() {
    }

    required public init(coder aDecoder: NSCoder) {
        self.accessToken = aDecoder.decodeObject(forKey: "access_token") as? SevenPassToken
        self.refreshToken = aDecoder.decodeObject(forKey: "refresh_token") as? SevenPassToken
        self.idToken = aDecoder.decodeObject(forKey: "id_token") as? String
        self.idTokenDecoded = aDecoder.decodeObject(forKey: "id_token_decoded") as? Dictionary<String, Any>
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: "access_token")
        aCoder.encode(refreshToken, forKey: "refresh_token")
        aCoder.encode(idToken, forKey: "id_token")
        aCoder.encode(idTokenDecoded, forKey: "id_token_decoded")
    }

}
