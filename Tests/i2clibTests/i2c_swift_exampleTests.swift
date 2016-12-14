import XCTest
@testable import i2clib

class i2c_swift_exampleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(i2c_swift_example().text, "Hello, World!")
    }


    static var allTests : [(String, (i2c_swift_exampleTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
