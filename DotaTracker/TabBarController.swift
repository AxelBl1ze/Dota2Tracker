//
//  TabBarController.swift
//  DotaTracker
//
//  Created by Ilya Sidnev on 1/31/25.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTabs()
        self.delegate = self
    }
    
    //MARK: tab setup:)
    
    private func setupTabs() {
        let home = self.createNav(with: "Home", and: UIImage(systemName: "house.fill"), vc: HomeViewController())
        let heroes = self.createNav(with: "Heroes", and: UIImage(systemName: "person.3.fill"), vc: HeroesViewController())
        let matches = self.createNav(with: "Matches", and: UIImage(systemName: "note.text"), vc: MatchesViewController())
        let profile = self.createNav(with: "Profile", and: UIImage(systemName: "person.crop.circle"), vc: UserViewController())
        self.setViewControllers([home, heroes, matches, profile], animated: true)
    }
    
    private func createNav(with title: String, and image: UIImage?, vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem.title = title
        nav.tabBarItem.image = image
        return nav
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        //заглушка
    }
}
