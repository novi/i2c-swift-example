import I2CDeviceModule
import Foundation

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    //formatter.timeZone = TimeZone(abbreviation: "JST")
    formatter.timeZone = TimeZone.current
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

let slack = SlackWebAPI(token: slackAPIToken)

/*// --- test
// post to slack
slack.sendMessage(channel: sendChannel, text: "🌡80°F(26.9°C) 🌀997.16hPa 🕒(2/8/17, 12:44 AM)", success: { (a, b) in
    
    print("slack sent", String(describing: a), String(describing: b))
    exit(0)
    
}) { (error) in
    print("slack send error", error)
    exit(-1)
}

sleep(10)
 exit(-1)
// --- test end
 */

// get current air pressure and temperature
let device = try getCurrentI2CDevice()

let sensor = BMP180(device: device)

try sensor.reset()

try sensor.calibrate()

let result = try sensor.mesure(oversampling: .oss3)

print("sensor data", result)

// build message

let temp = Float(result.temperature) / 10
let fahrenheit = 1.8 * Float(result.temperature) / 10 + 32
let press = Float(result.pressure) / 100 // in hpa

let tempStr = String(format: "%.0f°F(%.1f°C)", fahrenheit, temp)
let pressStr = String(format: "%.2fhPa", press)

let message = "🌡\(tempStr) 🌀\(pressStr) 🕒\(formatDate(Date()))"

print(message)

//exit(0)

// post to slack
slack.sendMessage(channel: sendChannel, text: message, success: { (a, b) in
    
    print("slack sent", String(describing: a), String(describing: b))
    exit(0)
    
}) { (error) in
    print("slack send error", error)
    exit(-1)
}


RunLoop.main.run()
//sleep(10)
