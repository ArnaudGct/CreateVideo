// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CreateVideo",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "App",
            path: ".",
            exclude: [
                "build_and_run.sh",
                "AppIcon.icns",
                "Gemini_Generated_Image_w2luc2w2luc2w2lu.png",
                "CreateVideo.app"
            ],
            sources: [
                "Models",
                "Services",
                "ViewModels",
                "Views",
                "CreateVideoApp.swift"
            ],
            resources: [
                .copy("Resources/Template_Montage_Video")
            ]
        )
    ]
)
