//
//  LoginView.swift
//  NGA
//
//  Created by Bugen Zhao on 7/1/21.
//

import Foundation
import WebKit
import SwiftUI
import WebView

struct LoginView: View {
  @StateObject var authStorage = AuthStorage.shared
  @StateObject var webViewStore: WebViewStore

  @State var authing = false

  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  init() {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
    let webView = WKWebView(frame: .zero, configuration: configuration)
    self._webViewStore = StateObject(wrappedValue: WebViewStore(webView: webView))
  }

  var body: some View {
    let inner =
      WebView(webView: webViewStore.webView)
      .onAppear {
      self.webViewStore.webView.load(URLRequest(url: URL(string: "https://ngabbs.com/nuke.php?__lib=login&__act=account&login")!))
    }.onReceive(timer) { _ in
      self.webViewStore.configuration.websiteDataStore.httpCookieStore.getAllCookies(authWithCookies)
    }

    #if os(iOS)
      NavigationView {
        inner
          .navigationTitle("Sign in to NGA")
          .navigationBarTitleDisplayMode(.inline)
          .navigationBarItems(trailing: Group {
          Button(action: close) {
            if authing {
              ProgressView()
            }
          }
        })
      }
    #elseif os(macOS)
      inner
        .frame(width: 300, height: 400)
    #endif
  }

  func authWithCookies(_ cookies: [HTTPCookie]) {
    guard let uid = cookies.first(where: { $0.name == "ngaPassportUid" })?.value else { return }
    guard let token = cookies.first(where: { $0.name == "ngaPassportCid" })?.value else { return }

    authing = true
    authStorage.setAuth(AuthInfo.with {
      $0.uid = uid
      $0.token = token
    })
    authing = false
  }

  func close() {
    authStorage.isSigning = false
  }
}

fileprivate struct LoginPreviewView: View {
  @EnvironmentObject var authStorage: AuthStorage

  var body: some View {
    NavigationView {
      VStack {
        Text("Authed as '\(authStorage.authInfo.inner.uid)'")
        Button(action: { authStorage.clearAuth() }) {
          Text("Show")
        }
      } .sheet(isPresented: $authStorage.isSigning, content: {
          LoginView()
        })
    }
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginPreviewView()
      .environmentObject(AuthStorage())
  }
}
