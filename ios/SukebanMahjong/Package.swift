// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SukebanMahjongCore",
    products: [
        .library(name: "SukebanMahjong", targets: ["SukebanMahjong"])
    ],
    targets: [
        .target(
            name: "SukebanMahjong",
            path: "SukebanMahjong",
            exclude: [
                "Assets.xcassets",
                "Resources",
                "PrivacyInfo.xcprivacy",
                "BattleView.swift",
                "CharacterColors.swift",
                "GameFeedback.swift",
                "GameProgress.swift",
                "GuideViews.swift",
                "PixelArt.swift",
                "RootView.swift",
                "SukebanMahjongApp.swift"
            ],
            sources: [
                "GameModels.swift",
                "CastData.swift",
                "MahjongModels.swift",
                "MahjongEngine.swift",
                "MatchSnapshot.swift",
                "StoryScenes.swift",
                "StoryChapterData.swift"
            ]
        ),
        .testTarget(
            name: "SukebanMahjongCoreTests",
            dependencies: ["SukebanMahjong"],
            path: "SukebanMahjongTests",
            sources: [
                "MahjongEngineTests.swift",
                "MatchSnapshotTests.swift",
                "StoryDataTests.swift"
            ]
        )
    ]
)
