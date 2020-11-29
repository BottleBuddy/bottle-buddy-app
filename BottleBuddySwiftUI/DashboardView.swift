//
//  DashboardView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/17/20.
//

import SwiftUI
import Firebase

struct DashboardView: View {        //why do i need this struct and Dashboard struct?
    var body: some View {
        Dashboard()
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}

struct Dashboard : View {
    var body: some View {
        TabView{
            HomePage()
                .tabItem{
                    VStack{
                    Image(systemName:"house" )
                    Text("Home")
                    }
            }.tag(1)
            
            ProfileView()
                  .tabItem{
                      VStack{
                      Image(systemName:"person.circle" )
                      Text("Profile")
                      }
            }.tag(2)
            
            SettingsView()
                .tabItem{
                    VStack{
                    Image(systemName:"gear" )
                    Text("Settings")
                    }
            }.tag(3)
            HealthView()
                .tabItem{
                    VStack{
                    Image(systemName:"heart" )
                    Text("Health")
                    }
            }.tag(4)
            
            UserDataView()
                .tabItem{
                    VStack{
                    Image(systemName:"star" )
                    Text("UserInfo")
                    }
            }.tag(5)
         }
    }
}


