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
    
    var body: some View {
        let bluetooth : Bluetooth
        bluetooth = Bluetooth.init()
        //hardcoded test buddies for now
        let first = Buddy(bottleID: "yeti", connected: true)
        let second = Buddy(bottleID: "hydroflask", connected: false)
        let third = Buddy(bottleID: "other", connected: false)
        let buddys = [first, second, third]
        
        return List(buddys) { buddy in
            BuddyRow(buddy: buddy)
            Button(action: {bluetooth.scanForDevices()}) {
                Text("Search For Devices")
            }
        }
    }
}

struct Buddy: Identifiable {
    var id = UUID()
    var bottleID: String = ""
    var connected: Bool = false
    
}

struct BuddyRow: View {
    var buddy: Buddy
    var body: some View {
        List{
            HStack{
                Text(buddy.bottleID)
                Spacer()
                Button(action: {connect()}) {
                    if !buddy.connected{    //if buddy is NOT connected
                        Text("CONNECT")
                    }
                    else {
                        Text("DISCONNECT")
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        
    }
    
    func connect(){
        if !buddy.connected {
            bluetoothInit()     //need to update .connected status
        }
        else {
            bluetoothClose()
        }
    }
}

func bluetoothInit(){
    let bluetooth = Bluetooth()
    bluetooth.initializeStream()
}

func bluetoothClose(){
    let bluetooth = Bluetooth()
    bluetooth.closeStream()
}



struct BluetoothConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothConnectView()
    }
}

