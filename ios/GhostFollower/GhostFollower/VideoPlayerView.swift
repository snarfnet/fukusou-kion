import AVFoundation
import SwiftUI

struct VideoPlayerView: UIViewRepresentable {
    var player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
