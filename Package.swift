import PackageDescription

let package = Package(
    name: "i2clib",
    targets: [
                Target(name: "i2clib", dependencies: ["CUSB"]),
                Target(name: "CUSB"),
                 ],
    dependencies: [],
    exclude: ["Xcode"]
)
