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
    let timer = Timer.publish(every: 0.3, on : .main, in: .common).autoconnect()
    @State var tof_distance = UInt16()
    @State var imu_reading = String()
    //var bluetooth = Bluetooth.init()
    //@EnvironmentObject var bluetooth: Bluetooth
    //@State var connected = false
    @State var connected_status = "Not Connected To Buddy :("
    let notifContent = UNMutableNotificationContent()
    @ObservedObject var notifcation = NotificationManager()
    @State var alert = false
    
    var body: some View{
        ScrollView(){
            VStack{
                Text("Bluetooth Connection")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(connected_status)")
                          .foregroundColor(Color(UIColor(named: "BB_DarkBlue")!))
                            .padding(.vertical)
                          .onReceive(timer){time in
                            if(bluetooth.connected){
                              connected_status = "Connected To Buddy!"
                            }
                            else{
                              connected_status = "Not Connected to Buddy :("
                            }
                          }
                Button(action: {connectBuddy()}) {
                    Text("Connect to Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {bluetooth.sendCallibrationService()}) {
                    Text("Callibrate Buddy")
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
                
//                Button(action: {
//
//                        self.notifcation.sendNotification(title: "Cleaning Started!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 2)
//
//                        bluetooth.writeData()}){
//                    Text("Clean My Buddy")
//                        .foregroundColor(.white)
//                        .padding(.vertical)
//                        .frame(width: UIScreen.main.bounds.width - 50)
//                        .background(Color(UIColor(named: "BB_DarkBlue")!))
//                        .cornerRadius(10)
//                }
//                .padding()
                //                Text("ToF Distance ")
                //                    .font(.title)
                //                    .fontWeight(.bold)
                //                    .foregroundColor(.white)
                //                Text("\(tof_distance)")
                //                    .onReceive(timer){time in
                //                        if(bluetooth.connected){
                //                            tof_distance = bluetooth.getTofValue()
                //                        }
                //                    }
                //                    .foregroundColor(Color(UIColor(named: "BB_DarkBlue")!))
                //                    .padding(.vertical)
                //                    .multilineTextAlignment(.center)
                //                    .font(.system(size: 30))
                //
                //                Text("IMU Orientation ")
                //                    .font(.title)
                //                    .fontWeight(.bold)
                //                    .foregroundColor(.white)
                //                Text("\(imu_reading)")
                //                    .onReceive(timer){time in
                //                        if(bluetooth.connected){
                //                            imu_reading = bluetooth.getIMUValue()
                //                        }
                //                    }
                //                    .foregroundColor(Color(UIColor(named: "BB_DarkBlue")!))
                //                    .padding(.vertical)
                //                    .multilineTextAlignment(.center)
                //                    .font(.system(size: 30))
                
                //                Button(action:{connected = true}){
                //                    Text("Tof Data")
                //                        .foregroundColor(.white)
                //                        .padding(.vertical)
                //                        .frame(width: UIScreen.main.bounds.width - 50)
                //                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                //                        .cornerRadius(10)
                //                }
                //                idk if this is the right bluetooth attribute to access the data
                //                let dataReceivedString = "\(result)"
                //                for num in result
                
                
                /*Text("Received Bluetooth Data:  + \(result)")*/
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxWidth: .infinity)
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        .frame(maxWidth: .infinity)
    }
    func connectBuddy(){
        bluetooth.scanForDevices()
        
    }
}

struct BluetoothConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothConnectView(tof_distance: 0, imu_reading: "\n X Value: \n Y Value: \n Z Value: ")
    }
}

