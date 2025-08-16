//
//  TabBarDelegateProxy.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import UIKit
import SwiftUI

final class TabBarDelegateProxy: NSObject, UITabBarControllerDelegate {
    static let shared = TabBarDelegateProxy()
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let index = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        NotificationCenter.default.post(name: .tabReselected, object: nil, userInfo: ["index": index])
    }
}

struct TabBarIntrospector: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { ProxyVC() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class ProxyVC: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            var parentResponder: UIResponder? = self
            while let responder = parentResponder {
                if let tbc = responder as? UITabBarController {
                    tbc.delegate = TabBarDelegateProxy.shared
                    break
                }
                parentResponder = responder.next
            }
        }
    }
}