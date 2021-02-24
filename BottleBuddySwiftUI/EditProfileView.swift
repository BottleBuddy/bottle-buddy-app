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
    //user cannot manually update these values
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var user_id: String = ""
    
    //user can manipulate these values
    @objc dynamic var bottleType = 4
    @objc dynamic var bottleSize = 1
    @objc dynamic var email = ""
    @objc dynamic var name = ""
    @objc dynamic var age = ""
    @objc dynamic var sex = 3
    @objc dynamic var weight = ""
    
    convenience init(uid: String, email: String){
        self.init()
        self.user_id = uid
        self.email = email
    }
    
    
    override static func primaryKey() -> String? {
        return "_id"
    }

}

struct EditProfileView: View {
    
    @EnvironmentObject var state: AppState
    
    let bblightblue = UIColor(named: "BB_LightBlue")
    @State var bottleType = 4
    @State var bottleSize = 1
    @State var email = ""
    @State var name = ""
    @State var age = ""
    @State var sex = 3
    @State var weight = ""
    
    @State var recieve = false //what is this for
    @State var notifNumber = 1 //what is this for
    @State var submit = false
    
    var body: some View {
        VStack{
            VStack{
                Form{
                    Section(header: Text("About You")){
                        TextField("Name: " + self.name , text: $name)
                        TextField("Age: " + self.age, text: $age)
                            .keyboardType(.numberPad)
                        TextField("Weight: " + self.weight, text: $weight)
                            .keyboardType(.numberPad)
                        Picker(selection: $sex, label: Text("Sex: " + String(self.sex))){
                            Text("Male").tag(1)
                            Text("Female").tag(2)
                            Text("Other").tag(3)
                            
                        }
                        TextField("Email: " + self.email , text: $email)
                    }
                    Section(header: Text("About Your Bottle")){
                        Picker(selection: $bottleType, label: Text("Water Bottle Brand: " + String(self.bottleType))){
                            Text("Yeti").tag(1)
                            Text("HydroFlask").tag(2)
                            Text("ThermoFlask").tag(3)
                            Text("None").tag(4)
                        }
                        Picker(selection: $bottleSize, label: Text("Water Bottle Size: " + String(self.bottleSize))){
                            Text("16oz").tag(1)
                            Text("18oz").tag(2)
                            Text("26oz").tag(3)
                            Text("36oz").tag(4)
                        }
                    }
                    Button(action: {
                        self.submit.toggle()
                        self.updateUserObject()
                    }){
                        Text("Submit")
                    }
                    .alert(isPresented:$submit){
                        Alert(title: Text("Profile Saved"))
                    }
                    
                }
            }.onAppear{
                self.bottleSize = state.userData!.bottleSize
                self.bottleType = state.userData!.bottleType
                self.email = state.userData!.email
                self.name = state.userData!.name
                self.age = state.userData!.age
                self.sex = state.userData!.sex
                self.weight = state.userData!.weight
            }
        }
    }

    struct EditProfileView_Previews: PreviewProvider {
        static var previews: some View {
            EditProfileView()
        }
    }
    
    
    
    func updateUserObject() {
        guard let realm = state.userData!.realm else {
            return
        }
        
        try! realm.write {
            state.userData!.bottleSize = self.bottleSize
            state.userData!.bottleType = self.bottleType
            state.userData!.email = self.email
            state.userData!.name = self.name
            state.userData!.age = self.age
            state.userData!.sex = self.sex
            state.userData!.weight = self.weight
        }
    }
}
