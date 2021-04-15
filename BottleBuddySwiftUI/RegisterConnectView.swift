//
//  RegisterConnectView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 4/14/21.
//

import SwiftUI
import CoreBluetooth
import os
import Foundation
import UserNotifications

struct RegisterConnectView: View {
    let bblightblue = UIColor(named: "BB_LightBlue")
    let timer = Timer.publish(every: 0.3, on : .main, in: .common).autoconnect()
    @State var tof_distance = UInt16()
    @State var imu_reading = String()
    //var bluetooth = Bluetooth.init()
    @EnvironmentObject var bluetooth: Bluetooth
    //@State var connected = false
    @State var connected_status = "Not Connected To Buddy :("
    let notifContent = UNMutableNotificationContent()
    @ObservedObject var notifcation = NotificationManager()
    @State var alert = false
    
    var body: some View{
        ScrollView(){
            VStack{
                Text("Initial Bluetooth Connection")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(connected_status)")
                    .onReceive(timer){time in
                        if(bluetooth.connected){
                            connected_status = "Connected To Buddy!"
                        }
                    }
                    .foregroundColor(Color(UIColor(named: "BB_DarkBlue")!))
                    .padding(.vertical)
                Button(action: {connectBuddy()}) {
                    Text("Connect to Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {bluetooth.disconnectDevice()}) {
                    Text("Disconnect Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {}) {
                    Text("Continue")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()

            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxWidth: .infinity)
            //.onAppear{bluetooth.initializeStream()}
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        .frame(maxWidth: .infinity)
    }
    func connectBuddy(){
        bluetooth.scanForDevices()
        
        //bluetooth.connectDevice()
        //if(foundPeripheral.state == .connected){
        //connected = true
        // }
    }
}

struct RegisterConnectView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterConnectView()
    }
}
