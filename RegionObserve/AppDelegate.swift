//
//  AppDelegate.swift
//  RegionObserve
//
//  Created by 罗泰 on 2019/1/7.
//  Copyright © 2019 chenwang. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.addUserNotification()
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}



// MARK: - UserNotification
extension AppDelegate {
    private func addUserNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [UNAuthorizationOptions.alert, UNAuthorizationOptions.badge, UNAuthorizationOptions.sound]) { (success, error) in
            if success
            {
                print("注册通知成功!")
                center.getNotificationSettings(completionHandler: { (setting) in
                    
                })
            }
            else
            {
                print("注册本地通知失败!")
            }
        }
    }
}


// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        
    }
    
    /// 后台收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let trigger = response.notification.request.trigger, !trigger.isKind(of: UNPushNotificationTrigger.self)
        {
            print("后台收到本地通知...")
            
        }
        completionHandler()
    }
    
    /// 前台收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let trigger = notification.request.trigger, !trigger.isKind(of: UNPushNotificationTrigger.self)
        {
            print("前台收到本地通知...")
            
        }
        completionHandler([UNNotificationPresentationOptions.sound, UNNotificationPresentationOptions.alert])
    }
}

