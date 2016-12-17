import XCTest
@testable import I2C

#if os(Linux)
    public func getCurrentI2CDevice() throws -> I2CDevice {
        do {
            return try I2CBusDevice(portNumber: 0)
        } catch {
            print(error)
            print("trying to connect i2c tiny usb device...")
            return try I2CTinyUSB()
        }
    }
    
#else
    
    public func getCurrentI2CDevice() throws -> I2CDevice {
        return try I2CTinyUSB()
    }
    
#endif


final class I2CTests: XCTestCase {
    
    func testDeviceConnected() throws {
        
        let device = try getCurrentI2CDevice()
        
        XCTAssertTrue(try device.write(toAddress: 0x23, data: [], readBytes: 0) == [])
        
        //device.closeDevice()
    }


    static var allTests : [(String, (I2CTests) -> () throws -> Void)] {
        return [
            ("testDeviceConnected", testDeviceConnected)
        ]
    }
}
