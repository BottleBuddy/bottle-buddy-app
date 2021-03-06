//
//  DashboardView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/17/20.
//

import SwiftUI
import Firebase
import RealmSwift

let USE_REALM_SYNC = true
let app = USE_REALM_SYNC ? App(id: "bottlebuddyrealm2-ohcmu") : nil

let bbdarkblue = UIColor(named: "BB_DarkBlue")
let bblightblue = UIColor(named: "BB_LightBlue")
let bbyellow = UIColor(named: "BB_Yellow")



struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}

struct Dashboard : View {
    @ObservedObject var state = AppState()
    //@ObservedObject var bluetooth : Bluetooth
    @State var error: Error?
    @State var firstDashboard: Bool = true
    
    var body: some View {
        TabView{
            HomePage()
                .tabItem{
                    VStack{
                        Image(systemName:"house")
                        Text("Home")
                    }
                }.tag(1)
                .environmentObject(state)
                .environmentObject(bluetooth)

            
            ProfileView()
                .tabItem{
                    VStack{
                        Image(systemName:"person.circle")
                        Text("Profile")
                    }
                }.tag(2)
                .environmentObject(state)
                .environmentObject(bluetooth)
            
//            waterReadingsView()
//                .tabItem{
//                    VStack{
//                        Image(systemName:"star")
//                        Text("Water Readings")
//                    }
//                }.tag(3)
//                .environmentObject(state)
//                .environmentObject(bluetooth)
            BluetoothConnectView(tof_distance: 0)
                .tabItem{
                    VStack{
                        Image(systemName:"paperplane")
                        Text("Bluetooth")
                    }
                }.tag(3)
                .environmentObject(state)
                .environmentObject(bluetooth)
            
        }
        .accentColor(Color(bbdarkblue!))
        .onAppear {
            UITabBar.appearance().barTintColor = bblightblue
            if(firstDashboard){
                guard let app = app else {
                    print("Not using Realm Sync - not logging in")
                    return
                }
                state.shouldIndicateActivity = true
                app.login(credentials: .anonymous).receive(on: DispatchQueue.main).sink(receiveCompletion: {
                    state.shouldIndicateActivity = false
                    switch ($0) {
                    case .finished:
                        break
                    case .failure(let error):
                        self.error = error
                    }
                }, receiveValue: {
                    self.error = nil
                    state.loginPublisher.send($0)
                }).store(in: &state.cancellables)
                
                bluetooth.setState(state: state)
                
                firstDashboard = false
            }
        }.disabled(state.shouldIndicateActivity)
    }
}



