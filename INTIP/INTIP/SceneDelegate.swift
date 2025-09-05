//
//  SceneDelegate.swift
//

import UIKit
import SystemConfiguration   // 네트워크 체크용

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // ⚡ window 초기화
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIViewController() // 임시 VC
        window?.makeKeyAndVisible()
        
        // ⚡ 앱 시작 시 네트워크 체크
        checkNetworkAndProceed()
    }

    // MARK: - 네트워크 체크 및 UI 로드
    private func checkNetworkAndProceed() {
        if !isConnectedToNetwork() {
            showNetworkAlert()
        } else {
            loadMainUI()
        }
    }

    private func showNetworkAlert() {
        guard let rootVC = window?.rootViewController else { return }

        let alert = UIAlertController(
            title: "네트워크 연결 실패",
            message: "네트워크가 연결되어 있지 않습니다. 연결 후 다시 시도해주세요.",
            preferredStyle: .alert
        )

        let retryAction = UIAlertAction(title: "재시도", style: .default) { [weak self] _ in
            self?.checkNetworkAndProceed()
        }
        alert.addAction(retryAction)

        let cancelAction = UIAlertAction(title: "앱 닫기", style: .cancel) { _ in
            // 앱 종료
            exit(0)
        }
        alert.addAction(cancelAction)


        // 화면이 완전히 표시된 후 alert 띄우기
        DispatchQueue.main.async {
            rootVC.present(alert, animated: true)
        }
    }

    private func loadMainUI() {
        let homeVC = HomeViewController()
        window?.rootViewController = UINavigationController(rootViewController: homeVC)
        window?.makeKeyAndVisible()
    }


    // MARK: - 네트워크 연결 여부 확인
    private func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil as CFAllocator?, $0)
            }
        }

        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) { return false }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return isReachable && !needsConnection
    }

    // MARK: UISceneDelegate 나머지 메서드
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
