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
    @EnvironmentObject var state: AppState
    
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, error in
            if granted == true && error == nil {
                print("Notifications permitted")
            } else {
                print("Notifications not permitted")
            }
        })
        drinkEarlyNotification()
        drinkMidNotification()
        drinkLateNotification()
        drinkFinalNotification()
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
    
    
    func drinkEarlyNotification() {
        var dateComponents = DateComponents()
        
        //9:05am reminder to drink
        dateComponents.hour = 9
        dateComponents.minute = 5
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Reminder to hydrate!"
        content.body = "Take a sip of water to meet 25% of your daily goal."
        content.badge = 1
        let request = UNNotificationRequest(identifier: "drinkEarlyNotif", content: content, trigger: trigger)
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
    
    func drinkMidNotification() {
        var dateComponents = DateComponents()
        
        //2:05 reminder to drink
        dateComponents.hour = 15
        dateComponents.minute = 16
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Reminder to hydrate!"
        content.body = "Drink more water in the next hour to meet your 50% goal."
        content.badge = 1
        let request = UNNotificationRequest(identifier: "drinkMidNotif", content: content, trigger: trigger)
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
    
    func drinkLateNotification() {
        var dateComponents = DateComponents()
        
        //5:05 reminder to drink
        dateComponents.hour = 17
        dateComponents.minute = 5
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Reminder to hydrate!"
        content.body = "Drink more water in the next hour to meet your 75% goal."
        content.badge = 1
        let request = UNNotificationRequest(identifier: "drinkLateNotif", content: content, trigger: trigger)
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
    
    func drinkFinalNotification() {
        var dateComponents = DateComponents()
        
        //8:05 reminder to drink
        dateComponents.hour = 20
        dateComponents.minute = 5
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Reminder to hydrate!"
        content.body = "Drink more water in the next hour to meet 100% of your daily goal!"
        content.badge = 1
        let request = UNNotificationRequest(identifier: "drinkFinalNotif", content: content, trigger: trigger)
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
