import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebAppView()
            .ignoresSafeArea()
            .background(Color(red: 0.98, green: 0.96, blue: 0.93))
    }
}

struct WebAppView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.userContentController.addUserScript(WKUserScript(
            source: """
            (function () {
              function show(message) {
                document.documentElement.style.background = '#fbfaf6';
                document.body.innerHTML = '<main style="font-family:-apple-system;padding:24px;background:#fbfaf6;color:#14231b;"><h1 style="font-size:22px;">画面の表示に失敗しました</h1><p style="line-height:1.7;">アプリ内ページのJavaScriptでエラーが起きました。</p><pre style="white-space:pre-wrap;background:#fff;padding:14px;border-radius:8px;">' + String(message).replace(/[&<>]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]; }) + '</pre></main>';
              }
              window.addEventListener('error', function (event) {
                show(event.message || 'JavaScript error');
              });
              window.addEventListener('unhandledrejection', function (event) {
                show(event.reason && (event.reason.stack || event.reason.message) || event.reason || 'Unhandled promise rejection');
              });
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1)

        if let indexURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            let resourceURL = Bundle.main.resourceURL ?? indexURL.deletingLastPathComponent()
            webView.loadFileURL(indexURL, allowingReadAccessTo: resourceURL)
        } else {
            webView.loadHTMLString(
                """
                <html lang="ja">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <body style="font-family:-apple-system;padding:24px;background:#fbfaf6;color:#14231b;">
                    <h1 style="font-size:22px;">WebAppが見つかりません</h1>
                    <p>アプリ内に index.html が含まれていません。</p>
                  </body>
                </html>
                """,
                baseURL: nil
            )
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard
                navigationAction.navigationType == .linkActivated,
                let url = navigationAction.request.url,
                ["http", "https"].contains(url.scheme?.lowercased())
            else {
                decisionHandler(.allow)
                return
            }

            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            showError(error, in: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            showError(error, in: webView)
        }

        private func showError(_ error: Error, in webView: WKWebView) {
            let message = error.localizedDescription
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            webView.loadHTMLString(
                """
                <html lang="ja">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <body style="font-family:-apple-system;padding:24px;background:#fbfaf6;color:#14231b;">
                    <h1 style="font-size:22px;">読み込みに失敗しました</h1>
                    <p style="line-height:1.7;">アプリ内ページを開けませんでした。</p>
                    <pre style="white-space:pre-wrap;background:#fff;padding:14px;border-radius:8px;">\(message)</pre>
                  </body>
                </html>
                """,
                baseURL: nil
            )
        }
    }
}
