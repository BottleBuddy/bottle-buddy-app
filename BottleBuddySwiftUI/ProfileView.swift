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
    @EnvironmentObject var state: AppState
    @EnvironmentObject var bluetooth: Bluetooth
    
    init(){
        healthStore = HealthStore()
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(){
                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                NavigationLink(destination: BluetoothConnectView(tof_distance: 0).environmentObject(bluetooth)){
                    Text("DEMO MODE")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
                NavigationLink(destination: EditProfileView().environmentObject(state)){
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
                    
                    guard let app = app else {
                        print("Not using Realm Sync - not logging out")
                        return
                    }
                    state.shouldIndicateActivity = true
                    app.currentUser?.logOut().receive(on: DispatchQueue.main).sink(receiveCompletion: { _ in }, receiveValue: {
                        state.shouldIndicateActivity = false
                        state.logoutPublisher.send($0)
                    }).store(in: &state.cancellables)
                    
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
