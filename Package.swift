import PackageDescription

let package = Package(
    name: "I2C",
    targets: [
                Target(name: "Counter", dependencies: ["I2CDeviceModule"]),
                Target(name: "I2CDeviceModule", dependencies: ["I2C"]),
                Target(name: "I2C", dependencies: ["CUSB"]),
                Target(name: "CUSB"),
                 ],
    dependencies: [],
    exclude: ["Xcode"]
)
