//
//  WebViewViewModel.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import Foundation
import WebKit

class WebViewViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = true
    @Published var progress: Double = 0.0
    
    var webView: WKWebView?
    var loadingTimeout: Timer? // Timer pre načítanie, niektoré stránky sa nenačítavú 100%
    
    override init() {
        super.init()
        self.webView = WebViewManager.shared.webView
        self.webView?.navigationDelegate = self
        setupProgressObserver()
    }
    
    func load(url: URL) {
        webView?.load(URLRequest(url: url))
        loadingTimeout?.invalidate()
        loadingTimeout = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.webViewDidEndLoadingManually()
        }
    }
    
    func webViewDidEndLoadingManually() {
        isLoading = false
        loadingTimeout?.invalidate()
        loadingTimeout = nil
    }
    
    // Spodný panel
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    
    // Indikátor načítavania
    private func setupProgressObserver() {
        webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress", let change = change, let newProgress = change[.newKey] as? Double {
            DispatchQueue.main.async {
                self.progress = newProgress
//                self.isLoading = self.webView?.isLoading ?? true
                self.isLoading = !(newProgress >= 1.0)
            }
        }
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            print("didStartProvisionalNavigation")
            self.isLoading = true
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            print("didFinish")
            print("back: \(webView.canGoBack) forward: \(webView.canGoForward)")
            self.isLoading = false
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed loading with error: \(error)")
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: "estimatedProgress")
        loadingTimeout?.invalidate()
    }
}

// Webview singleton
class WebViewManager: ObservableObject {
    static let shared = WebViewManager()
    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
}
