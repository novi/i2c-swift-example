import PackageDescription

let package = Package(
    name: "I2C",
    targets: [
                Target(name: "LightSens", dependencies: ["I2CDeviceModule"]),
                Target(name: "Counter", dependencies: ["I2CDeviceModule"]),
                Target(name: "I2CDeviceModule", dependencies: ["I2C"]),
                Target(name: "I2CDetect", dependencies: ["I2C"]),
                Target(name: "I2C", dependencies: ["CUSB"]),
                Target(name: "CUSB")
                 ],
    dependencies: [
        .Package(url: "https://www.github.com/sixtyfiveford/Ci2c.swift.git", majorVersion: 1),
    ],
    exclude: ["Xcode"]
)
