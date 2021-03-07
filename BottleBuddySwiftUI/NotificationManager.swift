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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, error in
            if granted == true && error == nil {
                print("Notifications permitted")
            } else {
                print("Notifications not permitted")
            }
        })
        drinkNotification()
        cleanReminderNotification()
    }
    
    func sendNotification(title: String, subtitle: String?, body: String, launchIn: Double) {
            
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.body = body
        print("reached notification method")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: launchIn, repeats: false)
        let request = UNNotificationRequest(identifier: "demoNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if error != nil
                {
                    print("Issue with sending notification")
                }
             })
        print("finished notification method")
    }
    
    
    func drinkNotification() {
        var dateComponents = DateComponents()
        
        //reminds user at the top of every hour to drink water
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,
                                                            repeats: true)
        let content = UNMutableNotificationContent()
                content.title = "Reminder to hydrate!"
                content.body = "Take a sip of water to meet your daily goal."
                content.badge = 1

                //Create the actual notification
                let request = UNNotificationRequest(identifier: "drinknotif",
                                                    content: content,
                                                    trigger: trigger)
                //Add our notification to the notification center
                UNUserNotificationCenter.current().add(request)
                {
                    (error) in
                    if let error = error
                    {
                        print("Uh oh! We had an error: \(error)")
                    }
                }
    }
    
    func cleanReminderNotification() {
        var dateComponents = DateComponents()
        
        //reminds the user to clean at 8am on Sundays
        dateComponents.day = 1
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,
                                                            repeats: true)
        let content = UNMutableNotificationContent()
                content.title = "Cleaning time!"
                content.body = "Secure your cap on the bottle and initiate cleaning withing the app."
                content.badge = 1

                //Create the actual notification
                let request = UNNotificationRequest(identifier: "cleannotif",
                                                    content: content,
                                                    trigger: trigger)
                //Add our notification to the notification center
                UNUserNotificationCenter.current().add(request)
                {
                    (error) in
                    if let error = error
                    {
                        print("Uh oh! We had an error: \(error)")
                    }
                }
    }
}


extension UIViewController: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler( [.alert, .sound])
    }
}
