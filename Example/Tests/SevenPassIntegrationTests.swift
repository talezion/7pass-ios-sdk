import XCTest
import SevenPass

class SevenPassIntegration: XCTestCase {
    
    // Use same instance of SevenPass for all integration tests (should reflect real-world usage).
    private lazy var sevenPass: SevenPass = {
        let configuration = SevenPassConfiguration(
            consumerKey: "56a0982fcd8fb606d000b233",
            consumerSecret: "2e7b77f99be28d80a60e9a2d2c664835ef2e02c05bf929f60450c87c15a59992",
            callbackUri: "oauthtest://oauth-callback",
            environment: "qa"
        )
        
        return SevenPass(configuration: configuration)
    }()
    
    private let testUsername = "prosiebendigital+7@gmail.com"
    private let testPassword = "Kunf_tiger7"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPasswordLogin() {
        let expectation = expectationWithDescription("Password Login")
        
        sevenPass.authorize(
            login: testUsername,
            password: testPassword,
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                XCTAssertNotNil(tokenSet.accessToken?.token)
                XCTAssertFalse(tokenSet.accessToken!.isExpired())
                XCTAssertNotNil(tokenSet.email)
                expectation.fulfill()
            },
            failure: { error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testRefreshToken() {
        let expectation = expectationWithDescription("Refresh Token")
        
        authorize { authTokenSet in
            guard let refreshToken = authTokenSet.refreshToken?.token else {
                XCTFail("Refresh token not set")
                return
            }
            
            self.sevenPass.authorize(refreshToken: refreshToken,
                success: { tokenSet in
                    XCTAssertNotNil(tokenSet.accessToken?.token)
                    XCTAssertNotNil(tokenSet.refreshToken?.token)
                    expectation.fulfill()
                },
                failure: { error in
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()
                }
            )
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testAccountDetails() {
        let expectation = expectationWithDescription("Get Account Details")
        
        authorize { authTokenSet in
            let accountClient = self.sevenPass.accountClient(authTokenSet)
            
            accountClient.get("me",
                success: { json, response in
                    guard let
                        status = json["status"] as? String,
                        data = json["data"] as? [String: AnyObject],
                        email = data["email"] as? String,
                        _ = data["email_verified"] as? String else {
                            XCTFail("JSON response invalid.")
                            return
                    }
                    
                    XCTAssertEqual(status, "success")
                    XCTAssertEqual(email, self.testUsername)
                    expectation.fulfill()
                },
                failure: { error in
                    XCTFail(error.localizedDescription)
                    expectation.fulfill()
                }
            )
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testEmailIsTaken() {
        let expectation = expectationWithDescription("Email is taken")
        
        fetchEmailAvailability(testUsername) { isAvailable in
            XCTAssertFalse(isAvailable)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testEmailIsAvailable() {
        let expectation = expectationWithDescription("Email is available")
        
        fetchEmailAvailability("prosiebendigital+42@gmail.com") { isAvailable in
            XCTAssertTrue(isAvailable)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testPasswordIsValid() {
        let expectation = expectationWithDescription("Password is valid")
        
        fetchPasswordValidity("kunftiger7") { isValid in
            XCTAssertTrue(isValid)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testPasswordIsInvalid() {
        let expectation = expectationWithDescription("Password is invalid")
        
        fetchPasswordValidity("12345") { isValid in
            XCTAssertFalse(isValid)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    // MARK: - Helper methods
    
    private func authorize(completion: SevenPassTokenSet -> Void) {
        sevenPass.authorize(
            login: testUsername,
            password: testPassword,
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                completion(tokenSet)
            },
            failure: { error in
                XCTFail(error.localizedDescription)
            }
        )
    }
    
    private func fetchCredentials(completion: SevenPassClient -> Void) {
        sevenPass.authorize(
            parameters: [
                "grant_type": "client_credentials",
            ],
            success: { tokenSet in
                completion(self.sevenPass.deviceCredentialsClient(tokenSet))
            },
            failure: { error in
                XCTFail(error.localizedDescription)
            }
        )
    }
    
    private func fetchEmailAvailability(email: String, completion: Bool -> Void) {
        fetchCredentials { deviceClient in
            deviceClient.post("checkMail",
                parameters: [
                    "email": email,
                    "flags": [
                        "client_id": self.sevenPass.configuration.consumerKey
                    ]
                ],
                success: { json, response in
                    if let
                        data = json["data"] as? [String: AnyObject],
                        available = data["available"] as? Bool {
                            completion(available)
                    } else {
                        XCTFail("Invalid json.")
                    }
                },
                failure: { error in
                    XCTFail(error.localizedDescription)
                }
            )
        }
    }
    
    private func fetchPasswordValidity(password: String, completion: Bool -> Void) {
        fetchCredentials { deviceClient in
            deviceClient.post("checkPassword",
                parameters: [
                    "password": password
                ],
                success: { json, response in
                    if let
                        data = json["data"] as? [String: AnyObject],
                        valid = data["accepted"] as? Bool {
                            completion(valid)
                    } else {
                        XCTFail("Invalid json.")
                    }
                },
                failure: { error in
                    XCTFail(error.localizedDescription)
                }
            )
        }
    }
    
}
