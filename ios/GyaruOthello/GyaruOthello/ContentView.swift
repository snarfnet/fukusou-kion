import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebGameView()
            .ignoresSafeArea()
            .background(Color.black)
    }
}

private struct WebGameView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false

        loadGame(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadGame(in webView: WKWebView) {
        guard let htmlURL = Bundle.main.url(
            forResource: "gyaru-othello",
            withExtension: "html",
            subdirectory: "Web"
        ) else {
            webView.loadHTMLString("<html><body style='background:#050505;color:white;font-family:-apple-system'>Game file missing.</body></html>", baseURL: nil)
            return
        }

        let readAccessURL = htmlURL.deletingLastPathComponent()
        webView.loadFileURL(htmlURL, allowingReadAccessTo: readAccessURL)
    }
}
