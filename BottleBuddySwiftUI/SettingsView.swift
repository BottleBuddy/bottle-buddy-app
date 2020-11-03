//
//  SettingsView.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/6/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @State var recieve = false
    @State var notifNumber = 1
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    
    init() {
        UITableView.appearance().backgroundColor = (bblightblue!)
    }
    
    var body: some View {
        NavigationView{

                Form{
                    Toggle(isOn: $recieve){
                        Text("Recieve Notifications")
                    }
                    Stepper(value: $notifNumber , in: 1...20){
                        Text("\(notifNumber) Notification\(notifNumber > 1 ? "s " : " " )per week")
                    }
                    
                }
            
            .navigationBarTitle("Settings")
        }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
