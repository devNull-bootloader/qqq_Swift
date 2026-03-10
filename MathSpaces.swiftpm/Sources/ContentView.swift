import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebAppView()
            .ignoresSafeArea()
    }
}

// MARK: - WKWebView wrapper

struct WebAppView: UIViewRepresentable {

    /// Background colour that matches the app's `--bg` CSS variable (#111111).
    private static let appBackground = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0)

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Allow inline media playback without requiring a user gesture
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Inject window._autoLaunch = true at document start so the app skips
        // the PWA install-prompt screen and goes straight to the calculator UI.
        let autoLaunch = WKUserScript(
            source: "window._autoLaunch = true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(autoLaunch)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isOpaque = true
        webView.backgroundColor = Self.appBackground

        // Load index.html from the bundled Resources folder
        if let htmlURL = Bundle.main.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: "Resources"
        ) {
            // Grant read access to the entire Resources directory so that
            // relative imports of app.js, styles.css, icons/, etc. resolve.
            let resourcesDir = htmlURL.deletingLastPathComponent()
            webView.loadFileURL(htmlURL, allowingReadAccessTo: resourcesDir)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
