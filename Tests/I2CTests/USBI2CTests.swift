import XCTest
@testable import I2C

final class USBI2CTests: XCTestCase {
    
    func testDeviceConnected() throws {
        
        let device = try I2CTinyUSB()
        
        XCTAssertTrue(try device.write(toAddress: 0x23, data: [], readBytes: 0) == [])
        
        device.closeDevice()
    }


    static var allTests : [(String, (USBI2CTests) -> () throws -> Void)] {
        return [
            //("testScanDevice", testScanDevice),
            ("testDeviceConnected", testDeviceConnected)
        ]
    }
}
