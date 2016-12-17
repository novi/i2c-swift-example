import XCTest
@testable import I2C

final class USBI2CTests: XCTestCase {
    
    func testScanDevice() throws {
        
        let device = try I2CTinyUSB()
        
        var addr = 0x08 as UInt8
        while addr <= 0x77 {
            
            let addrStr = String(format: "0x%lx", addr)
            
            usleep(50_000); // 50ms wait
            
            print("sending... to", addrStr)
            
            if try device.sendAck(addr: addr) {
                print("device found at", addrStr)
            }
            addr += 1
        }
        
        device.closeDevice()
    }
    
    
    func testDeviceConnected() throws {
        
        let device = try I2CTinyUSB()
        
        XCTAssertTrue(try device.sendAck(addr: 0x23))
        
        device.closeDevice()
    }


    static var allTests : [(String, (USBI2CTests) -> () throws -> Void)] {
        return [
            ("testScanDevice", testScanDevice),
            ("testDeviceConnected", testDeviceConnected)
        ]
    }
}
