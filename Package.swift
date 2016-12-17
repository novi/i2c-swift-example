import PackageDescription

let package = Package(
    name: "I2C",
    targets: [
                Target(name: "I2C", dependencies: ["CUSB"]),
                Target(name: "CUSB"),
                 ],
    dependencies: [],
    exclude: ["Xcode"]
)
