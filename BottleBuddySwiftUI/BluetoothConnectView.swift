//
//  BluetoothConnectView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 2/7/21.
//

import SwiftUI
import CoreBluetooth
import os
import Foundation

struct BluetoothConnectView: View {
    let bblightblue = UIColor(named: "BB_LightBlue")
    
    var bluetooth = Bluetooth.init()
    
    var body: some View{
        ScrollView(){
            VStack{
                Text("Bluetooth")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Button(action: {bluetooth.scanForDevices()}) {
                    Text("Search For Devices")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {bluetooth.connectDevice()}) {
                    Text("Connect")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxWidth: .infinity)
            .onAppear{bluetooth.initializeStream()}
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        .frame(maxWidth: .infinity)
    }
}

struct Buddy: Identifiable {
    var id = UUID()
    var bottleID: String = ""
    var connected: Bool = false    
}

struct BluetoothConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothConnectView()
    }
}

