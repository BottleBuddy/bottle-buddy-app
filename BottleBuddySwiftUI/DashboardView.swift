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
let app = USE_REALM_SYNC ? App(id: "bottlebuddyrealm-ucenr") : nil

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}

struct Dashboard : View {
    @ObservedObject var state = AppState()
    @State var error: Error?
    
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

            
            ProfileView()
                .tabItem{
                    VStack{
                        Image(systemName:"person.circle")
                        Text("Profile")
                    }
                }.tag(2)
                .environmentObject(state)
            
            UserDataView()
                .tabItem{
                    VStack{
                        Image(systemName:"star")
                        Text("UserInfo")
                    }
                }.tag(3)
                .environmentObject(state)
        }.onAppear {
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
        }.disabled(state.shouldIndicateActivity)
    }
}



