import Foundation
import I2C
import I2CDeviceModule

final class MyZT8Seg: ZT8SegDevice {
    let device: DeviceWrap
    let address: UInt8 = 0x51
    init<D: I2CDevice>(_ d: D) throws {
        device = DeviceWrap(d)
    }
}

let device = try getCurrentI2CDevice()

let sensor = BMP180(device: device)

let zt8 = try MyZT8Seg(device)

try zt8.resume()

print("LED module version", try zt8.getVersion())

while true {
    
    let result = try sensor.mesure(oversampling: .oss3)
    
    let temp = Float(result.temperature) / 10
    try zt8.setString("\(UInt(temp))")
    
    sleep(1)
    
    let press = Float(result.pressure) / 100
    
    try zt8.setString("\(UInt(press))")
    
    sleep(1)
}
