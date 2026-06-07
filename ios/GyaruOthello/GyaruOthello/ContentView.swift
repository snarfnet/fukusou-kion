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
        guard let htmlURL = findGameHTML() else {
            webView.loadHTMLString(
                errorHTML("ゲームファイルがアプリ内に見つかりません。"),
                baseURL: nil
            )
            return
        }

        let readAccessURL = Bundle.main.resourceURL ?? htmlURL.deletingLastPathComponent()
        webView.loadFileURL(htmlURL, allowingReadAccessTo: readAccessURL)
    }

    private func findGameHTML() -> URL? {
        if let url = Bundle.main.url(
            forResource: "gyaru-othello",
            withExtension: "html",
            subdirectory: "Web"
        ) {
            return url
        }

        if let url = Bundle.main.url(forResource: "gyaru-othello", withExtension: "html") {
            return url
        }

        guard let resourceURL = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(
                at: resourceURL,
                includingPropertiesForKeys: nil
              ) else {
            return nil
        }

        for case let url as URL in enumerator where url.lastPathComponent == "gyaru-othello.html" {
            return url
        }

        return nil
    }

    private func errorHTML(_ message: String) -> String {
        """
        <!doctype html>
        <html lang="ja">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <body style="margin:0;background:#050505;color:#fff;font-family:-apple-system,BlinkMacSystemFont,sans-serif;display:grid;place-items:center;min-height:100vh;">
          <main style="padding:24px;text-align:center;line-height:1.6;">
            <h1 style="font-size:22px;margin:0 0 12px;">ギャルオセロを読み込めませんでした</h1>
            <p style="font-size:15px;margin:0;color:#f2c15d;">\(escapeHTML(message))</p>
          </main>
        </body>
        </html>
        """
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
