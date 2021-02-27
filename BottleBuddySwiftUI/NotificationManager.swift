//
//  NotificationManager.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 2/25/21.
//

import Foundation
import SwiftUI
import UserNotifications

class NotificationManager: ObservableObject {
    var notifications = [Notification]()
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                print("Notifications permitted")
            } else {
                print("Notifications not permitted")
            }
        }
    }
    
    func sendNotification(title: String, subtitle: String?, body: String, launchIn: Double) {
            
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.body = body
        print("reached notification method")
//        let imageName = "logo"
//        guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") else { return }
//        let attachment = try! UNNotificationAttachment(identifier: imageName, url: imageURL, options: .none)
//        content.attachments = [attachment]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: launchIn, repeats: false)
        let request = UNNotificationRequest(identifier: "demoNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

extension UIViewController: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        completionHandler( [.alert, .badge, .sound])
    }
}
