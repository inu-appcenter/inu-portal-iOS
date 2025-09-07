import UIKit
import WebKit
import FirebaseMessaging

class HomeViewController: UIViewController {
    private let rootUrl = "https://intip.inuappcenter.kr/m/home"
//    private let rootUrl = "https://intip-test.pages.dev/m/home"
    private var webView: WKWebView!
    private var previousPath: String?
    
    private var fcmToken: String = ""             // 발급된 FCM 토큰 저장
    private var isWebViewLoaded: Bool = false     // 웹뷰 로딩 상태 체크

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

    // MARK: - WebView 설정
    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "loginSuccess")
        contentController.add(self, name: "routeChange")
        
        let loginScriptSource = """
        if (window.localStorage.getItem('tokenInfo')) {
            window.webkit.messageHandlers.loginSuccess.postMessage('ok');
        }
        """
        let loginScript = WKUserScript(source: loginScriptSource,
                                       injectionTime: .atDocumentEnd,
                                       forMainFrameOnly: true)
        contentController.addUserScript(loginScript)
        
        let routeObserverScriptSource = """
        (function() {
            function notifyPath() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.routeChange) {
                    window.webkit.messageHandlers.routeChange.postMessage(window.location.pathname);
                }
            }
            window.addEventListener('popstate', notifyPath);
            window.addEventListener('pushState', notifyPath);
            window.addEventListener('replaceState', notifyPath);
            notifyPath();
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
        let routeObserverScript = WKUserScript(source: routeObserverScriptSource,
                                               injectionTime: .atDocumentEnd,
                                               forMainFrameOnly: true)
        contentController.addUserScript(routeObserverScript)
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 뒤로가기 제스처 허용
        webView.allowsBackForwardNavigationGestures = true
    }

    private func setupURL() {
        if let url = URL(string: rootUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }



}

// MARK: - WKScriptMessageHandler
extension HomeViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "routeChange", let path = message.body as? String {
            print("📍 React Router 경로 변경 감지:", path)
            
            // 🔹 뒤로가기 제스처 제어
            let restrictedPaths: Set<String> = [
                "/m/home",
                "/m/bus",
                "/m/save",
                "/m/mypage"
            ]
            
            if restrictedPaths.contains(path) {
                webView.allowsBackForwardNavigationGestures = false
                print("🚫 뒤로가기 제스처 차단됨 (\(path))")
            } else {
                webView.allowsBackForwardNavigationGestures = true
                print("✅ 뒤로가기 제스처 허용됨 (\(path))")
            }
            
            // 🔹 로그인 → 홈 이동 시 FCM 전달
            if previousPath == "/m/login" && path == "/m/home" {
                print("🎉 로그인에서 홈으로 이동 감지됨")
//                postFcmTokenToWebView()
            }
            
            previousPath = path
        }
    }
}

// MARK: - FCM 토큰 발급 및 웹뷰 전달
extension HomeViewController {
    private func fetchFcmToken() {
        Messaging.messaging().token { [weak self] token, error in
            guard let self = self else { return }
            if let token = token {
                self.fcmToken = token
                print("📌 발급된 FCM 토큰:", token)
                self.postFcmTokenToWebView()
            } else if let error = error {
                print("FCM 토큰 발급 실패:", error)
            }
        }
    }
    
    private func postFcmTokenToWebView() {
        guard isWebViewLoaded, !fcmToken.isEmpty else { return }

        // JS 문자열 생성 (문자열로 전달)
        let js = "window.onReceiveFcmToken && window.onReceiveFcmToken('\(fcmToken)'); void(0);"
        print(fcmToken)

        // 웹뷰에서 JS 실행
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("❌ FCM 토큰 전달 실패:", error)
            } else {
                print("✅ FCM 토큰 웹뷰 전달 완료")
            }
        }
    }


}


// MARK: - WKUIDelegate, WKNavigationDelegate
extension HomeViewController: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ 페이지 로드 완료:", webView.url?.absoluteString ?? "")
        isWebViewLoaded = true
        
        // 웹뷰 로딩 완료 후 FCM 토큰 발급
        fetchFcmToken()
    }


    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .cancel) { _ in completionHandler() })
        DispatchQueue.main.async { self.present(alertController, animated: true) }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .default) { _ in completionHandler(false) })
        alertController.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in completionHandler(true) })
        present(alertController, animated: true)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}


