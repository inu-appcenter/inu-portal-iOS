//
//  MainTabBarController.swift
//  INTIP
//
//  Created by 이대현 on 12/7/24.
//

import UIKit

class MainTabBarController: UITabBarController {
    private lazy var mainTabBarController : UITabBarController = {
        let viewController = UITabBarController()
        return viewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTabBarItem()
    }


    func setupTabBarItem() {
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        let saveVC = UINavigationController(rootViewController: SaveViewController())
        let writeVC = UINavigationController(rootViewController: WriteViewController())
        let mypageVC = UINavigationController(rootViewController: MyPageViewController())
        
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "icon_home_active"), tag: 0)
        saveVC.tabBarItem = UITabBarItem(title: "Save", image: UIImage(named: "icon_input"), tag: 1)
        writeVC.tabBarItem = UITabBarItem(title: "Write", image: UIImage(named: "icon_group"), tag: 2)
        mypageVC.tabBarItem = UITabBarItem(title: "Mypage", image: UIImage(named: "icon_profile"), tag: 3)
        
        self.viewControllers = [homeVC, saveVC, writeVC, mypageVC]
        self.tabBar.tintColor = UIColor(hexCode: "9CAFE2")
    }
}
