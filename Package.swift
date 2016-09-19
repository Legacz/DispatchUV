import PackageDescription

let package = Package(
  name:         "DispatchUV",
  targets:      [
    Target(name: "DispatchUV")
  ],
  dependencies: [
    .Package(url: "../CLibUV", // "https://github.com/NozeIO/CLibUV.git",
             majorVersion: 0)
  ]
)
