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

final class userObject: Object, ObjectKeyIdentifiable {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var user_id: String = uid
    @objc dynamic var bottleType = 4
    @objc dynamic var bottleSize = 1
    @objc dynamic var email = ""
    @objc dynamic var submit = false
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    @objc dynamic var age = ""
    @objc dynamic var sex = 3
    @objc dynamic var weight = ""
    @objc dynamic var recieve = false
    @objc dynamic var notifNumber = 1
    
    
    override static func primaryKey() -> String? {
        return "_id"
    }

}

struct EditProfileView: View {
    
    @EnvironmentObject var state: AppState
    @EnvironmentObject var user: User
    var userObj: userObject
    
    let bblightblue = UIColor(named: "BB_LightBlue")
    @State var bottleType = 4
    @State var bottleSize = 1
    @State var email = ""
    @State var submit = false
    @State var firstName = ""
    @State var lastName = ""
    @State var age = ""
    @State var sex = 3
    @State var weight = ""
    @State var recieve = false
    @State var notifNumber = 1
    
    init() {
        self.userObj = userObject()
    }
    
    var body: some View {
        VStack{
            VStack{
                Form{
                    Section(header: Text("About You")){
                        TextField("First Name" , text: $firstName)
                        TextField("Last Name" , text: $lastName)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                        TextField("Weight", text: $weight)
                            .keyboardType(.numberPad)
                        Picker(selection: $sex, label: Text("Sex")){
                            Text("Male").tag(1)
                            Text("Female").tag(2)
                            Text("Other").tag(3)
                            
                        }
                        TextField("Your email" , text: $email)
                    }
                    Section(header: Text("About Your Bottle")){
                        Picker(selection: $bottleType, label: Text("Water Bottle Brand")){
                            Text("Yeti").tag(1)
                            Text("HydroFlask").tag(2)
                            Text("ThermoFlask").tag(3)
                            Text("None").tag(4)
                        }
                        Picker(selection: $bottleSize, label: Text("Water Bottle Size")){
                            Text("16oz").tag(1)
                            Text("18oz").tag(2)
                            Text("26oz").tag(3)
                            Text("36oz").tag(4)
                        }
                    }
                    Button(action: {
                        self.submit.toggle()
                        self.addUserObject()
                    }){
                        //TODO: submit data to database
                        Text("Submit")
                    }
                    .alert(isPresented:$submit){
                        Alert(title: Text("Profile Saved"))
                    }
                    
                }
            }
        }
    }

    struct EditProfileView_Previews: PreviewProvider {
        static var previews: some View {
            EditProfileView()
        }
    }
    
    func addUserObject() {
        let newUserObject = userObject()
        
        newUserObject.age = age
        newUserObject.bottleSize = bottleSize
        newUserObject.bottleType = bottleType
        newUserObject.email = email
        newUserObject.firstName = firstName
        newUserObject.lastName = lastName
        newUserObject.notifNumber = notifNumber
        
        let currentUser = app?.currentUser
        
        let config = currentUser!.configuration(partitionValue: uid)
        
        Realm.asyncOpen(configuration: config) { result in
            switch result {
            case .failure(let error):
                print("Failed to open realm: \(error.localizedDescription)")
                // handle error
            case .success(let realm):
                print("Successfully opened realm: \(realm)")
                try! realm.write{
                    realm.add(newUserObject)
                }
            }
        }
        
        
    }
        
    
    private func commit(){
        
//        print("userobj uid:" + userObj.user_id)
//
//        guard let realm = userObj.realm else {
//            print("realm not opened")
//            userObj.age = age
//            userObj.bottleSize = bottleSize
//            userObj.bottleType = bottleType
//            userObj.email = email
//            userObj.firstName = firstName
//            userObj.lastName = lastName
//            userObj.notifNumber = notifNumber
//            return
//        }
//        try! realm.write{
//            print("writing object to realm")
//            userObj.age = age
//            userObj.bottleSize = bottleSize
//            userObj.bottleType = bottleType
//            userObj.email = email
//            userObj.firstName = firstName
//            userObj.lastName = lastName
//            userObj.notifNumber = notifNumber
//        }
    }
}
