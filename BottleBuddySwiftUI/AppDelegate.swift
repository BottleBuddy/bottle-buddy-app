//
//  AppDelegate.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/10/20.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse,
                withCompletionHandler completionHandler:
                   @escaping () -> Void) {
       // Get the meeting ID from the original notification.
            
       if response.notification.request.content.title ==
            "Cleaning time!" {
                
          switch response.actionIdentifier {
          case "ACCEPT_ACTION":
            bluetooth.writeData() //idk if this is the right function to call for cleaning
             break
                    
          case "DECLINE_ACTION":
             
             break
                    
          case UNNotificationDefaultActionIdentifier,
               UNNotificationDismissActionIdentifier:
             // Queue meeting-related notifications for later
             //  if the user does not act.
             
             break
                    
          default:
             break
            
          }
       }
       else {
          // Handle other notification types...
       }
            
       // Always call the completion handler when done.
       completionHandler()
    }
    
    
}

