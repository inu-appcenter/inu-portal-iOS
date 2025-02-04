//
//  MyPageViewController.swift
//  INTIP
//
//  Created by 이대현 on 12/7/24.
//

import UIKit
import WebKit

class MyPageViewController: UIViewController {
    private let rootUrl = "https://intip.inuappcenter.kr/app/mypage"
    private var lastLogined = false
    private var webView = WKWebView()
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupURL()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        Task {
            let currentStatus = await checkLogin()
            if self.lastLogined != currentStatus {
                print("login status change detected, reload page")
                self.lastLogined = currentStatus
                self.setupURL()
            }
        }
    }
    
    private func setupURL() {
        if let url = URL(string: rootUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    private func checkLogin() async -> Bool {
        let result = try? await self.webView.evaluateJavaScript("window.localStorage.getItem('tokenInfo');")
        if result != nil,
           let data = result as? String,
           let tokenInfo = try? JSONDecoder().decode(TokenInfo.self, from: data.data(using: .utf8)!) {
            print(tokenInfo)
            return true
        } else {
            return false
        }
    }
}

extension MyPageViewController: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) {
            _ in completionHandler()
        }
        
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText ?? ""
        }
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { action in completionHandler("") }))
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { action in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler("")
            }
        }))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        alertController.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { (action) in
            completionHandler(true)
        }))
        
        present(alertController, animated: true)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlString = navigationAction.request.url?.absoluteString ?? ""
        print(urlString)
        
        if urlString == "https://intip.inuappcenter.kr/app/home" {
            webView.load(URLRequest(url: URL(string: rootUrl)!))
            self.tabBarController?.selectedIndex = 0
            decisionHandler(.cancel)
            return
        }
        
        if urlString != rootUrl {
            self.tabBarController?.tabBar.isHidden = true
        } else {
            self.tabBarController?.tabBar.isHidden = false
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            self.tabBarController?.tabBar.standardAppearance = tabBarAppearance
            self.tabBarController?.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
        Task {
            self.lastLogined = await checkLogin()
            print("logined : ", self.lastLogined)
        }
    }
}
