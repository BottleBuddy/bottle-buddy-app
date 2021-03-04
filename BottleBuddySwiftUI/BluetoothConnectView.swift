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
    let timer = Timer.publish(every: 1, on : .main, in: .common).autoconnect()
    @State var result = UInt8()
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
                Button(action: {bluetooth.disconnectDevice()}) {
                    Text("Disconnect")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                
                //TextField(<#LocalizedStringKey#>, text: <#Binding<String>#>)
                
                Button(action:{bluetooth.writeData()}){
                    Text("Write Data")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
//                Button(action:{result = bluetooth.getTofValue()}){
//                    Text("Tof Data")
//                        .foregroundColor(.white)
//                        .padding(.vertical)
//                        .frame(width: UIScreen.main.bounds.width - 50)
//                        .background(Color(UIColor(named: "BB_DarkBlue")!))
//                        .cornerRadius(10)
//                }
                //idk if this is the right bluetooth attribute to access the data
                //let dataReceivedString = "\(result)"
                //for num in result
               
                    
                Text("Received Bluetooth Data:  + \(result)")
                    .onReceive(timer){time in
                        result = bluetooth.getTofValue()
                        
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

