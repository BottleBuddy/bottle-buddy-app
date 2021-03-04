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
import UserNotifications

struct BluetoothConnectView: View {
    let bblightblue = UIColor(named: "BB_LightBlue")
    let timer = Timer.publish(every: 0.5, on : .main, in: .common).autoconnect()
    @State var result = UInt8()
    var bluetooth = Bluetooth.init()
    @State var connected = false
    let notifContent = UNMutableNotificationContent()
    @ObservedObject var notifcation = NotificationManager()
    
    var body: some View{
        ScrollView(){
            VStack{
                Text("Bluetooth")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
//                Button(action: {bluetooth.scanForDevices()}) {
//                    Text("Search For Devices")
//                        .foregroundColor(.white)
//                        .padding(.vertical)
//                        .frame(width: UIScreen.main.bounds.width - 50)
//                        .background(Color(UIColor(named: "BB_DarkBlue")!))
//                        .cornerRadius(10)
//                }
//                .padding()
                
                Button(action: {connectBuddy()}) {
                    Text("Connect to Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                Button(action: {bluetooth.disconnectDevice()}) {
                    Text("Disconnect")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    //TODO: initiate cleaning protocol on button click
                    self.notifcation.sendNotification(title: "Cleaning Started!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 5)
                    
                bluetooth.writeData()}){
                    Text("Clean My Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                Button(action:{connected = true}){
                    Text("Tof Data")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                //                idk if this is the right bluetooth attribute to access the data
                //                let dataReceivedString = "\(result)"
                //                for num in result
                
                
                Text("Received Bluetooth Data:  + \(result)")
                    .onReceive(timer){time in
                        if(connected){
                            result = bluetooth.getTofValue()
                        }
                        
                        
                    }
                
                
                
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxWidth: .infinity)
            .onAppear{bluetooth.initializeStream()}
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        .frame(maxWidth: .infinity)
    }
    func connectBuddy(){
        bluetooth.scanForDevices()
        bluetooth.connectDevice()
        connected = true
    }
}

//struct Buddy: Identifiable {
//    var id = UUID()
//    var bottleID: String = ""
//    var connected: Bool = false
//}

struct BluetoothConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothConnectView(result: 0)
    }
}

