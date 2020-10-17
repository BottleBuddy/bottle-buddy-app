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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
}
