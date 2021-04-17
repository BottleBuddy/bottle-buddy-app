//
//  EditProfileView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 2/7/21.
//

import SwiftUI
import Firebase
import Combine
import RealmSwift

var time = Date()
var day = 0

final class userObject: Object, ObjectKeyIdentifiable {
    //user cannot manually update these values
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var user_id: String = ""
    
    //user can manipulate these values
    @objc dynamic var bottleBrandName = 0
    @objc dynamic var bottleSize = 0
    @objc dynamic var email = ""
    @objc dynamic var name = ""
    @objc dynamic var ageOfUser = ""
    @objc dynamic var sex = 0
    @objc dynamic var weight = ""
    
    convenience init(uid: String, email: String, name: String, bottleSize: Int, bottleBrandName: Int, weight: String){
        self.init()
        self.user_id = uid
        self.email = email
        self.name = name
        self.bottleSize = bottleSize
        self.bottleBrandName = bottleBrandName
        self.weight = weight
    }
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
}

struct EditProfileView: View {
    
    @EnvironmentObject var state: AppState
    
    let bblightblue = UIColor(named: "BB_LightBlue")
    @State var bottleBrandName = 0
    @State var bottleSize = 0
    @State var email = ""
    @State var name = ""
    @State var ageOfUser = ""
    @State var sex = 0
    @State var weight = ""
    @State var submit = false
    @State var firstDisplay = true
    @State var cleanTime = Date()
    @State var cleanDate = 0
    
    var body: some View {
        
        NavigationView{
            VStack{
                Text("Edit Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Form{
                    Section(header: Text("About You")){
                        Text("Name: " + self.name)
                        TextField("Age: " + self.ageOfUser, text: $ageOfUser)
                            .keyboardType(.numberPad)
                        TextField("Weight: " + self.weight, text: $weight)
                            .keyboardType(.numberPad)
                        Text("Sex: " + String(self.sex))
                        Text("Bottle brand: " + String(self.bottleBrandName))
                        Text("Bottle size: " + String(self.bottleSize))
                        Picker(selection: $cleanDate, label: Text("Day for cleaning reminders")){
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                            Text("Tuesday").tag(3)
                            Text("Wednesday").tag(4)
                            Text("Thursday").tag(5)
                            Text("Friday").tag(6)
                            Text("Saturday").tag(7)
                        }
                        DatePicker("Time for cleaning reminders: ", selection: $cleanTime, displayedComponents: [.hourAndMinute])
                    }
                    
                }
                
                Button(action: {
                    time = cleanTime
                    day = cleanDate
                    print("hour " + String(Calendar.current.dateComponents([.hour], from: time).hour ?? 0))
                    print("min " + String(Calendar.current.dateComponents([.minute], from: time).minute ?? 0))
                    cleanReminderNotification()
                    self.submit.toggle()
                    self.updateUserObject()
                }){
                    Text("Submit")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                }
                .background(Color(UIColor(named: "BB_DarkBlue")!))
                .cornerRadius(10)
                .padding()
                .alert(isPresented:$submit){
                    Alert(title: Text("Profile Saved"))
                }
                
                
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .onAppear{
                if(firstDisplay) {
                    self.bottleSize = state.userData!.bottleSize
                    self.bottleBrandName = state.userData!.bottleBrandName
                    self.email = state.userData!.email
                    self.name = state.userData!.name
                    self.ageOfUser = state.userData!.ageOfUser
                    self.sex = state.userData!.sex
                    self.weight = state.userData!.weight
                    firstDisplay = false
                }
            }
        }
    
        .background(Color(bblightblue!).ignoresSafeArea())
    }
    
    
    struct EditProfileView_Previews: PreviewProvider {
        static var previews: some View {
            EditProfileView().previewLayout(.fixed(width: 375, height: 1000))        }
    }
    
    func cleanReminderNotification() {
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        let selectedHour = Calendar.current.dateComponents([.hour], from: time).hour
        let selectedMinute = Calendar.current.dateComponents([.minute], from: time).minute
       
        dateComponents.hour = selectedHour
        dateComponents.minute = selectedMinute
        
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
              title: "Accept",
              options: UNNotificationActionOptions(rawValue: 0))
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
              title: "Decline",
              options: UNNotificationActionOptions(rawValue: 0))
        // Define the notification type
        let meetingInviteCategory =
              UNNotificationCategory(identifier: "cleanRequest",
              actions: [acceptAction, declineAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([meetingInviteCategory])
        
        let trigger = UNCalendarNotificationTrigger(dateMatching:dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Cleaning time!"
        content.body = "Secure your cap on the bottle and initiate cleaning withing the app."
        content.badge = 1
        content.categoryIdentifier = "cleanRequest"
        //Create the actual notification
        let request = UNNotificationRequest(
            identifier: "cleannotif",
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
    
    
    
    func updateUserObject() {
        
        guard let realm = state.userData!.realm else {
            return
        }
        
        try! realm.write {
            state.userData!.bottleSize = self.bottleSize
            state.userData!.bottleBrandName = self.bottleBrandName
            state.userData!.email = self.email
            state.userData!.name = self.name
            state.userData!.ageOfUser = self.ageOfUser
            state.userData!.sex = self.sex
            state.userData!.weight = self.weight
        }
    }
}
