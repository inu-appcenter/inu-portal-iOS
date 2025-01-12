//
//  WriteViewController.swift
//  INTIP
//
//  Created by 이대현 on 12/7/24.
//

import AVFoundation
import UIKit
import WebKit

class WriteViewController: UIViewController {
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
        checkCameraPermission()
    }
    
    private func setupURL() {
        let urlString = "https://intip.inuappcenter.kr/app/write"
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { isGranted in
            if isGranted {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
            }
        }
    }
}
