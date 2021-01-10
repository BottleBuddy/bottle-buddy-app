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
    
    let bblightblue = UIColor(named: "BB_LightBlue")
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
    @State var recieve = false
    @State var notifNumber = 1
    
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
                        Button(action: {self.submit.toggle()}){
                            //TODO: submit data to database
                            Text("Submit")
                        }
                        .alert(isPresented:$submit){
                            Alert(title: Text("Profile Saved"))
                        }
                        
                    }
                }
                
                HStack{
                    Form{
                        Toggle(isOn: $recieve){
                            Text("Recieve Notifications")
                        }
                        Stepper(value: $notifNumber , in: 1...20){
                            Text("\(notifNumber) Notification\(notifNumber > 1 ? "s " : " " )per week")
                        }
                    }
                }
                
                HStack{
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
        .background(Color(bblightblue!).ignoresSafeArea())
                .onAppear{
                    if let healthStore = healthStore{
                        healthStore.requestAuthorization { success in
                            if(success){
                                print(success)
                            }
                        }
                    }
                }
        
        .navigationBarTitle("Profile")
    }
    
    
    
    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            ProfileView()
        }
    }
}
