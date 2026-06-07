import SwiftUI

struct GhostOverlayView: View {
    var point: PersonTrackPoint?
    var settings: GhostSettings
    var time: Double

    var body: some View {
        Canvas { context, size in
            var context = context
            GhostRenderer.draw(in: &context, canvasSize: size, point: point, settings: settings, time: time)
        }
        .allowsHitTesting(false)
    }
}
