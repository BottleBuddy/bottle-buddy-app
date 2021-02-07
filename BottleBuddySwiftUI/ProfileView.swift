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
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(){
                
                NavigationLink(destination: BluetoothConnectView()){
                    Text("Bluetooth")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
                NavigationLink(destination: EditProfileView()){
                    Text("Edit Profile Information")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
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
                .padding()
                
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxWidth: .infinity)
            .navigationBarTitle("Profile")
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        .frame(maxWidth: .infinity)
  
    }
    
    
    
    struct ProfileView_Previews: PreviewProvider {
        static var previews: some View {
            ProfileView()
        }
    }
}
