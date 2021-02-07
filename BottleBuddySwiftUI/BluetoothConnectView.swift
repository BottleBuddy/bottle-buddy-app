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
        let first = Buddy(bottleID: "yeti", connected: false)
        let second = Buddy(bottleID: "hydroflask", connected: false)
        let third = Buddy(bottleID: "other", connected: false)
        let buddys = [first, second, third]
        
        return List(buddys) { buddy in
            BuddyRow(buddy: buddy)
        }
    }
}

struct Buddy: Identifiable {
    var id = UUID()
    var bottleID: String
    var connected: Bool = false;
    
//    mutating func connect(){
//        self.connected = true;
//    }
    
}

struct BuddyRow: View {
    
    var buddy: Buddy
    var body: some View {
        List{
            HStack{
                Text(buddy.bottleID)
                Spacer()
                Button(action: {connect()}) {
                    Text("CONNECT")
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        
    }
}

//temporary connect method to make it compile
func connect(){
    
}


struct BluetoothConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothConnectView()
    }
}

