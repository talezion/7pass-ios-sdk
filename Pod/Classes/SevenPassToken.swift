//
//  SevenPassToken.swift
//  SevenPass
//
//  Created by Jan Votava on 12/01/16.
//
//

public class SevenPassToken: NSObject, NSCoding {
    public let token: String
    public let expiresAt: Date

    public init(token: String, expiresAt: Date) {
        self.token = token
        self.expiresAt = expiresAt
    }

    public convenience init(token: String, expiresIn: TimeInterval) {
        let currentDate = Date()
        let expiresAt = currentDate.addingTimeInterval(expiresIn)

        self.init(token: token, expiresAt: expiresAt)
    }

    public required init(coder aDecoder: NSCoder) {
        self.token = aDecoder.decodeObject(forKey: "token") as! String
        self.expiresAt = aDecoder.decodeObject(forKey: "expires_at") as! Date
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(token, forKey: "token")
        aCoder.encode(expiresAt, forKey: "expires_at")
    }

    public func isExpired() -> Bool {
        let currentDate = Date()

        return expiresAt.compare(currentDate) == ComparisonResult.orderedAscending
    }
}
