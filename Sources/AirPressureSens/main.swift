import Foundation
import I2CDeviceModule

let device = try getCurrentI2CDevice()

let module = BMP180(device: device)

try module.calibrate()

while true {
    
    usleep(100 * 1000)
    
    let result = try module.mesure(oversampling: .oss3)
    
    print(result)
}
