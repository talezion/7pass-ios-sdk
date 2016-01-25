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
    public var idTokenDecoded: Dictionary<String, AnyObject>?

    public var email: String? {
        return idTokenDecoded?["email"] as? String
    }

    override init() {
    }

    required public init(coder aDecoder: NSCoder) {
        self.accessToken = aDecoder.decodeObjectForKey("access_token") as? SevenPassToken
        self.refreshToken = aDecoder.decodeObjectForKey("refresh_token") as? SevenPassToken
        self.idToken = aDecoder.decodeObjectForKey("id_token") as? String
        self.idTokenDecoded = aDecoder.decodeObjectForKey("id_token_decoded") as? Dictionary<String, AnyObject>
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(accessToken, forKey: "access_token")
        aCoder.encodeObject(refreshToken, forKey: "refresh_token")
        aCoder.encodeObject(idToken, forKey: "id_token")
        aCoder.encodeObject(idTokenDecoded, forKey: "id_token_decoded")
    }

}
