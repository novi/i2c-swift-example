import Foundation
import I2CDeviceModule

let device = try getCurrentI2CDevice()

let module = SHT21(device: device)

while true {
    
    usleep(100 * 1000)
    
    let t = try module.mesureTemperature()
    let rh = try module.mesureRH()
    
    let string = String(format: "%.2f°C, %.2f%%", t, rh)
    print(string)
}
