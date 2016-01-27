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
            }
        )
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    func testRefreshToken() {
        let expectation = expectationWithDescription("Refresh Token")
        
        fetchTokens { accessToken, refreshToken in
            self.sevenPass.authorize(refreshToken: refreshToken,
                success: { tokenSet in
                    XCTAssertNotNil(tokenSet.accessToken?.token)
                    XCTAssertNotNil(tokenSet.refreshToken?.token)
                    expectation.fulfill()
                },
                failure: { error in
                    XCTFail(error.localizedDescription)
                }
            )
        }
        
        waitForExpectationsWithTimeout(10) { _ in }
    }
    
    // MARK: - Helper methods
    
    private func fetchTokens(completion: (accessToken: String, refreshToken: String) -> Void) {
        sevenPass.authorize(
            login: testUsername,
            password: testPassword,
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                guard let
                    token = tokenSet.accessToken?.token,
                    refreshToken = tokenSet.refreshToken?.token else {
                        XCTFail("Token not set.")
                        return
                }
                completion((accessToken: token, refreshToken: refreshToken))
            },
            failure: { error in
                XCTFail(error.localizedDescription)
            }
        )
    }
    
}
