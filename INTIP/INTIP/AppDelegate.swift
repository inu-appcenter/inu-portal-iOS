//
//  AppDelegate.swift
//  INTIP
//
//  Created by 이대현 on 12/7/24.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 알림 권한 요청 및 대리자 설정
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions, completionHandler: { _, _ in }
        )
        
        // 원격 알림 등록
        application.registerForRemoteNotifications()
        
        // Firebase Messaging 대리자 설정
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    // MARK: APNs 토큰 전달
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // APNs 토큰을 Firebase에 전달
        Messaging.messaging().apnsToken = deviceToken
        
        // APNs 토큰을 문자열로 변환하여 출력 (선택 사항)
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs 토큰:", tokenString)
        
        // FCM 토큰 가져오기 및 출력
        Messaging.messaging().token { token, error in
            if let error = error {
                print("FCM 토큰 가져오기 실패:", error)
            } else if let token = token {
                print("🥳 FCM 토큰:", token)
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("원격 알림 등록 실패:", error)
    }
}

// MARK: Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
    
    // FCM 토큰이 갱신될 때 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
    }
}

// MARK: UNUserNotificationCenter Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 앱이 포그라운드 상태일 때 알림이 도착하면 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .badge, .sound])
    }
    
    // 사용자가 알림을 탭했을 때 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
