//
//  Bluetooth.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 2/7/21.
//

import Foundation
import UIKit
import CoreBluetooth
import os


/*
 THINGS THAT NEED HOMES
 
 let peripheralManager = CBPeripheralManager(
 delegate: self,
 queue: nil,
 options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
 )
 */


/*  NewService
 *  Description: Creates a new service with specified characteristic(s)
 *  Usage: Make this structure whenever you want to make a new service
 */
struct NewService{
    var serviceUUID: CBUUID!
    var characteristicUUID: CBUUID!
    init(testService: String, testCharacteristic: String){
        self.serviceUUID = CBUUID(string: testService)
        self.characteristicUUID = CBUUID(string: testCharacteristic)
    }
}

class Bluetooth: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate{
    var centralManager: CBCentralManager!
    
    var peripheralManager: CBPeripheralManager!
    
    var peripheralTransferCharacteristic: CBMutableCharacteristic?
    
    var centralTransferCharacteristic: CBCharacteristic?
    
    //which piece of hardware we are connected to
    var connectedCentral: CBCentral?
    
    //what hardware is connected to right now as a central device.
    var connectedPeripheral: CBPeripheral?
    
    //data we will actuall send not receive.
    var dataToSend = Data()
    
    //data we will recieve, not send
    var dataRecieved = Data()
    
    var sendingEOM :Bool = false   //sending end of message
    
    
    let mainService = NewService(
        testService: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961",
        testCharacteristic: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
    override init(){
        sendingEOM = false
    }
    
    func initializeStream(){
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: true])
        
        
        if let connectedPeripheral = connectedPeripheral{
            os_log("Connecting to peripheral %@", connectedPeripheral)
            self.connectedPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
            //deviceTableView.reloadData()      //reloads the data after you connect so you can change the type of button from connect to disconnect
            os_log("CONNECTED")
        }
        else {
            os_log("fucked up")
        }
        
        
    }
    
    func closeStream(){
        centralManager.stopScan()   //stops looking for devices (the bottle cap)
        dataRecieved.removeAll(keepingCapacity: false)  //clearing BLE queue
        peripheralManager.stopAdvertising()     //this advertises to the bottle cap,,, may not need (ask josh and zane what they decide)
    }
    
    func scanForDevices(){
        os_log("Scanning for Devices...")
        centralManager.scanForPeripherals(
            withServices: [mainService.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
        //retrievePeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch central.authorization {
                case .denied:
                    os_log("You are not authorized to use Bluetooth")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
        
        /*  sendData
         *  Description: Standard sendData() function from Apple's Example code. Personally, I did not change anything in this function because I was just testing.
         *  Usage: Call this function to actually send the data (as a peripheral) to another device. However, the way it is sent is up to you.
         */
        
        
        //sending from phone to cap
        func sendData() {
            var sendDataIndex = 0
            //Below defines the transferCharacteristic for this transfer and immediately returns if it is null/nil
            guard let transferCharacteristic = peripheralTransferCharacteristic else {return}
            //Below checks to see if we are suppose to be sending the end of message
            if sendingEOM {
                // send it
                let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
                // Did it send?
                if didSend {
                    // It did, so mark it as sent
                    sendingEOM = false
                    os_log("Sent: EOM")
                }
                // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
                return
            }
            // We're not sending an EOM, so we're sending data
            // Is there any left to send?
            if sendDataIndex >= dataToSend.count {
                // No data left.  Do nothing
                return
            }
            
            // There's data left, so send until the callback fails, or we're done.
            var didSend = true
            while didSend {
                
                // Work out how big it should be
                var amountToSend = dataToSend.count - sendDataIndex
                if let mtu = connectedCentral?.maximumUpdateValueLength {
                    amountToSend = min(amountToSend, mtu)
                }
                
                // Copy out the data we want
                let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
                
                // Send it
                didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
                
                // If it didn't work, drop out and wait for the callback
                if !didSend {
                    return
                }
                
                let stringFromData = String(data: chunk, encoding: .utf8)
                os_log("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
                
                // It did send, so update our index
                sendDataIndex += amountToSend
                // Was it the last one?
                if sendDataIndex >= dataToSend.count {
                    // It was - send an EOM
                    
                    // Set this so if the send fails, we'll send it next time
                    ViewController.sendingEOM = true
                    
                    //Send it
                    let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!,
                                                                for: transferCharacteristic, onSubscribedCentrals: nil)
                    
                    if eomSent {
                        // It sent; we're all done
                        sendingEOM = false
                        os_log("Sent: EOM")
                    }
                    return
                }
            }
        }
        
        
        /*  cleanUp()
         *  Call this when things either go wrong, or you're done with the connection.
         *  This cancels any subscriptions if there are any, or straight disconnects if not.
         *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
         */
        func cleanup() {
            // Don't do anything if we're not connected
            guard let connectedPeripheral = connectedPeripheral,
                  case .connected = connectedPeripheral.state else { return }
            
            for service in (connectedPeripheral.services ?? [] as [CBService]) {
                for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                    if characteristic.uuid == mainService.characteristicUUID && characteristic.isNotifying {
                        // It is notifying, so unsubscribe
                        self.connectedPeripheral?.setNotifyValue(false, for: characteristic)
                    }
                }
            }
            // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
            //Possibly will need to add the code below back
            //centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        
        /*  writeData
         *  Description: Write some test data to a peripheral
         *  Usage: This differs from sendData() because this writes the data to a peripheral as a central device
         */
        //this will change a tad based on pipeline,, but v important
        func writeData() {
            
            guard let connectedPeripheral = connectedPeripheral,
                  let transferCharacteristic = centralTransferCharacteristic
            else { return }
            
            let mtu = connectedPeripheral.maximumWriteValueLength (for: .withoutResponse)
            var rawPacket = [UInt8]()
            
            let bytesToCopy: size_t = min(mtu, dataRecieved.count)
            dataRecieved.copyBytes(to: &rawPacket, count: bytesToCopy)
            let packetData = Data(bytes: &rawPacket, count: bytesToCopy)
            
            let stringFromData = String(data: packetData, encoding: .utf8)
            os_log("Writing %d bytes: %s", bytesToCopy, String(describing: stringFromData))
            
            connectedPeripheral.writeValue(packetData, for: transferCharacteristic, type: .withoutResponse)
        }
    }
    
    
}
