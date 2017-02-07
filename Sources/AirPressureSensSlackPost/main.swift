import SlackKit
import I2CDeviceModule
import Foundation

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    //formatter.timeZone = TimeZone(abbreviation: "JST")
    //formatter.timeZone = TimeZone.current
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

#if Xcode
    typealias SlackWebAPI = WebAPI
#endif

let slack = SlackWebAPI(token: slackAPIToken)

// get current air pressure and temparature
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

let message = String(format: "🌡%.0f°F(%.1f°C) 🌀%.2fhPa 🕒(%@)", fahrenheit, temp, press, formatDate(Date()))

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
