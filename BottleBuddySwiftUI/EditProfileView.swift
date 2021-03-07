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
    @objc dynamic var bottleBrandName = 0
    @objc dynamic var bottleSize = 0
    @objc dynamic var email = ""
    @objc dynamic var name = ""
    @objc dynamic var ageOfUser = ""
    @objc dynamic var sex = 0
    @objc dynamic var weight = ""
    
    convenience init(uid: String, email: String, name: String){
        self.init()
        self.user_id = uid
        self.email = email
        self.name = name
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
    
    var body: some View {
        
        NavigationView{
            VStack{
                Text("Edit Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Form{
                    Section(header: Text("About You")){
                        TextField("Name: " + self.name , text: $name)
                        TextField("Age: " + self.ageOfUser, text: $ageOfUser)
                            .keyboardType(.numberPad)
                        TextField("Weight: " + self.weight, text: $weight)
                            .keyboardType(.numberPad)
                        Picker(selection: $sex, label: Text("Sex")){
                            Text("Male").tag(1)
                            Text("Female").tag(2)
                            Text("Other").tag(3)
                            
                        }
                        TextField("Email: " + self.email , text: $email)
                    }
                    
                    Section(header: Text("About Your Bottle")){
                        
                        Picker(selection: $bottleBrandName, label: Text("Bottle Brand")){
                            Text("Yeti").tag(1)
                            Text("Hydroflask").tag(2)
                            Text("Thermoflask").tag(3)
                            Text("Other").tag(4)
                        }
                        
                        Picker(selection: $bottleSize, label: Text("Bottle Size")){
                            Text("16 oz").tag(1)
                            Text("18 oz").tag(2)
                            Text("26 oz").tag(3)
                            Text("36 oz").tag(4)
                        }
                    }
                    
                }
                
                Button(action: {
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
