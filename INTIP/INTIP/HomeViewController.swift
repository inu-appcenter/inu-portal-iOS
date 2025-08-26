//
//  HomeViewController.swift
//  INTIP
//
//  Created by 이대현 on 12/7/24.
//

import UIKit
import WebKit
import FirebaseMessaging

class HomeViewController: UIViewController {
    private let rootUrl = "https://intip.inuappcenter.kr/m/home"
    private var webView: WKWebView!
    private var previousPath: String? // 👈 직전 경로 저장용 추가
    
    override func loadView() {
        super.loadView()
        setupWebView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupURL()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "loginSuccess")
        contentController.add(self, name: "routeChange") // 👈 경로 변경 감지용 추가
        
        // 로그인 성공 여부 확인
        let loginScriptSource = """
        if (window.localStorage.getItem('tokenInfo')) {
            window.webkit.messageHandlers.loginSuccess.postMessage('ok');
        }
        """
        let loginScript = WKUserScript(source: loginScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(loginScript)
        
        // React Router 라우트 변경 감지 스크립트
        let routeObserverScriptSource = """
        (function() {
            function notifyPath() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.routeChange) {
                    window.webkit.messageHandlers.routeChange.postMessage(window.location.pathname);
                }
            }
            window.addEventListener('popstate', notifyPath); // 뒤로가기/앞으로가기
            window.addEventListener('pushState', notifyPath); // 사용자 정의 이벤트
            window.addEventListener('replaceState', notifyPath);
            notifyPath(); // 초기 로딩 시 한번 호출
            // pushState/replaceState를 가로채서 이벤트 발생
            (function(history){
                var pushState = history.pushState;
                history.pushState = function(state) {
                    pushState.apply(history, arguments);
                    window.dispatchEvent(new Event('pushState'));
                };
                var replaceState = history.replaceState;
                history.replaceState = function(state) {
                    replaceState.apply(history, arguments);
                    window.dispatchEvent(new Event('replaceState'));
                };
            })(window.history);
        })();
        """
        let routeObserverScript = WKUserScript(source: routeObserverScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(routeObserverScript)
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        print("setupWebView 완료")
    }
    
    private func setupURL() {
        if let url = URL(string: rootUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    private func postFcmTokenToServer(fcmToken: String) async {
        guard let url = URL(string: "https://portal.inuappcenter.kr/api/tokens") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["token": fcmToken]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ FCM 토큰 등록 성공")
            } else {
                print("❌ FCM 토큰 등록 실패")
            }
        } catch {
            print("서버 전송 오류:", error)
        }
    }
    
    private func issueFcmTokenAndPost() async {
        do {
            try await Messaging.messaging().deleteToken() // 기존 토큰 삭제
            let newToken = try await Messaging.messaging().token()
            print("📌 발급된 FCM 토큰:", newToken)
            await postFcmTokenToServer(fcmToken: newToken)
        } catch {
            print("FCM 토큰 처리 실패:", error)
        }
    }
}

// MARK: - WKScriptMessageHandler
extension HomeViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "routeChange", let path = message.body as? String {
            print("📍 React Router 경로 변경 감지:", path)
            
            if let prev = previousPath {
                print("🔙 직전 경로:", prev)
            }
            
            // 직전 경로가 /m/login이고 현재 경로가 /m/home일 때만 실행
            if previousPath == "/m/login" && path == "/m/home" {
                print("🎉 로그인 완료 후 홈으로 이동 감지됨")
                
                // localStorage에서 tokenInfo 확인
                let js = "window.localStorage.getItem('tokenInfo');"
                webView.evaluateJavaScript(js) { result, error in
                    if let error = error {
                        print("❌ tokenInfo 확인 오류:", error)
                        return
                    }
                    
                    if let jsonString = result as? String,
                       let data = jsonString.data(using: .utf8) {
                        do {
                            if let tokenInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let accessToken = tokenInfo["accessToken"] as? String,
                               !accessToken.isEmpty {
                                print("✅ accessToken 존재:", accessToken.prefix(10), "…")
                                Task {
                                    await self.issueFcmTokenAndPost()
                                }
                            } else {
                                print("⚠️ tokenInfo는 있으나 accessToken 없음")
                            }
                        } catch {
                            print("❌ tokenInfo 파싱 실패:", error)
                        }
                    } else {
                        print("⚠️ tokenInfo 없음")
                    }
                }
            }
            
            // 마지막에 항상 previousPath 업데이트
            previousPath = path
            
        }
    }
}


// MARK: - WKUIDelegate, WKNavigationDelegate
extension HomeViewController: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let urlString = webView.url?.absoluteString {
            print("✅ 페이지 로드 완료:", urlString)
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlString = navigationAction.request.url?.absoluteString {
            print("➡️ 페이지 이동 시도:", urlString)
        }
        decisionHandler(.allow)
    }
    
    // JS alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .cancel) { _ in completionHandler() })
        DispatchQueue.main.async { self.present(alertController, animated: true) }
    }
    
    // JS confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .default) { _ in completionHandler(false) })
        alertController.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in completionHandler(true) })
        present(alertController, animated: true)
    }
    
    // 새 창 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
