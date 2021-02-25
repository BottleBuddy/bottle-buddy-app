//
//  DashboardView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/17/20.
//

import SwiftUI
import Firebase

struct DashboardView: View {//why do i need this struct and Dashboard struct?
    @EnvironmentObject var user: User
    
    var body: some View {
        Dashboard().environmentObject(user)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}

struct Dashboard : View {
    @EnvironmentObject var user: User
    @ObservedObject var state = AppState()
    
    var body: some View {
        TabView{
            HomePage()
                .tabItem{
                    VStack{
                    Image(systemName:"house" )
                    Text("Home")
                    }
            }.tag(1)
            .environmentObject(user)
            .environmentObject(state)

            
            ProfileView()
                  .tabItem{
                      VStack{
                      Image(systemName:"person.circle" )
                      Text("Profile")
                      }
            }.tag(2)
            .environmentObject(user)
            .environmentObject(state)
            
            UserDataView()
                .tabItem{
                    VStack{
                    Image(systemName:"star" )
                    Text("UserInfo")
                    }
                }.tag(3)
                .environmentObject(user)
                .environmentObject(state)
        }.onAppear {
            uid = user.uid
            state.partitionValue = user.uid
        }
    }
}


