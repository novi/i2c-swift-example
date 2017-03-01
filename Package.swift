import PackageDescription

let package = Package(
    name: "I2CExample",
    targets: [
                Target(name: "HumiditySens", dependencies: ["I2CDeviceModule"]),
                Target(name: "AirPressureSensDisplay", dependencies: ["I2CDeviceModule"]),
                Target(name: "LightSensDisplay", dependencies: ["I2CDeviceModule"]),
                Target(name: "AirPressureSens", dependencies: ["I2CDeviceModule"]),
                Target(name: "LightSens", dependencies: ["I2CDeviceModule"]),
                Target(name: "Counter", dependencies: ["I2CDeviceModule"]),
                Target(name: "I2CDetect", dependencies: ["I2CDeviceModule"]),
                Target(name: "I2CDeviceModule")
                 ],
    dependencies: [
        .Package(url: "https://www.github.com/novi/i2c-swift.git", majorVersion: 0),
    ],
    exclude: ["Xcode"]
)
