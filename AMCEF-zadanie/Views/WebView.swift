//
//  WebView.swift
//  AMCEF-zadanie
//
//  Created by Marek Meriač on 15/04/2024.
//

import SwiftUI
import WebKit

struct WebView: View {
    @StateObject var viewModel: WebViewViewModel
    let urlString: String
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView(value: viewModel.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 2)
            }
            SwiftUIWebView(viewModel: viewModel).disabled(viewModel.isLoading)
            HStack {
                Button(action: {
                    viewModel.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                }.disabled(!(viewModel.canGoBack) || viewModel.isLoading)
                Spacer()
                Button(action: {
                    viewModel.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding()
                }.disabled(viewModel.isLoading)
                Spacer()
                Button(action: {
                    viewModel.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .padding()
                }.disabled(!(viewModel.canGoForward) || viewModel.isLoading)
            }
            .padding()
            .frame(height: 44)
        }
        .onAppear {
            if let url = URL(string: urlString) {
                viewModel.load(url: url)
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}

struct SwiftUIWebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        return viewModel.webView ?? WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}

