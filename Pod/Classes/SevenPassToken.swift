//
//  SevenPassToken.swift
//  SevenPass
//
//  Created by Jan Votava on 12/01/16.
//
//

public class SevenPassToken: NSObject, NSCoding {
    public let token: String
    public let expiresAt: NSDate

    public init(token: String, expiresAt: NSDate) {
        self.token = token
        self.expiresAt = expiresAt
    }

    public convenience init(token: String, expiresIn: NSTimeInterval) {
        let currentDate = NSDate()
        let expiresAt = currentDate.dateByAddingTimeInterval(expiresIn)

        self.init(token: token, expiresAt: expiresAt)
    }

    public required init(coder aDecoder: NSCoder) {
        self.token = aDecoder.decodeObjectForKey("token") as! String
        self.expiresAt = aDecoder.decodeObjectForKey("expires_at") as! NSDate
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(token, forKey: "token")
        aCoder.encodeObject(expiresAt, forKey: "expires_at")
    }

    public func isExpired() -> Bool {
        let currentDate = NSDate()

        return expiresAt.compare(currentDate) == NSComparisonResult.OrderedAscending
    }
}
