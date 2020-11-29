//
//  ProfileView.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/6/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//

import SwiftUI
import HealthKit
import Firebase

struct ProfileView: View {
    
    
    private var healthStore:  HealthStore?
    @State private var newPeople : [User] = [User]()
    
    init(){
        healthStore = HealthStore()
    }
    @State var bottleType = 4
    @State var bottleSize = 1
    @State var email = ""
    @State var submit = false
    @State var firstName = ""
    @State var lastName = ""
    @State var age = ""
    @State var sex = 3
    @State var weight = ""
    
    var body: some View {
        NavigationView{
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
                    
                    Button(action: {self.submit.toggle()}){
                        Text("Submit")
                    }
                    .alert(isPresented:$submit){
                        Alert(title: Text("Profile Saved"))
                    }
                    
                    Button(action: {
                        try! Auth.auth().signOut()
                        UserDefaults.standard.set(false, forKey: "status")
                        NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
                    }) {
                        Text("Log out")
                            .foregroundColor(.white)
                            .padding(.vertical)
                            .frame(width: UIScreen.main.bounds.width - 50)
                    }
                    .background(Color(UIColor(named: "BB_DarkBlue")!))
                    .cornerRadius(10)
                }
                
            }
        }
        .onAppear{
            if let healthStore = healthStore{
                healthStore.requestAuthorization { success in
                    if(success){
                        print(success)
                        //                           sex = updatePersonSex(personSex: healthStore.getSex())
                    }
                }
            }
        }
        
        .navigationBarTitle("Profile")
    }
    
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
