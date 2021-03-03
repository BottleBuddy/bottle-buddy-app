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


// Make this structure whenever you want to make a new service
struct NewService{
    var serviceUUID: CBUUID!
    var characteristicUUID: CBUUID!
    init(testService: String, testCharacteristic: String){
        self.serviceUUID = CBUUID(string: testService)
        self.characteristicUUID = CBUUID(string: testCharacteristic)
    }
}

class Bluetooth: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject, Identifiable{
    var centralManager: CBCentralManager!
    
    var peripheralManager: CBPeripheralManager!
    
    var peripheralTransferCharacteristic: CBMutableCharacteristic?
    
    var centralTransferCharacteristic: CBCharacteristic?
    
    //which piece of hardware we are connected to
    var connectedCentral: CBCentral?
    
    //what hardware is connected to right now as a central device.
    var connectedPeripheral: CBPeripheral!
    
    //data we will actuall send not receive.
    var dataToSend = Data()
    
    //data we will recieve, not send
    var dataRecieved = Data()
    
    var sendingEOM :Bool = false   //sending end of message
    
    
    //let mainService = NewService(
        //testService: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961",
        //testCharacteristic: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
    
    let mainService = NewService(testService: "19B10010-E8F2-537E-4F6C-D104768A1214", testCharacteristic: "19B10013-E8F2-537E-4F6C-D104768A1214")
    
    override init(){
        sendingEOM = false      //this is j to make things compile,, may need to change later
    }
    
    func initializeStream(){
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: nil)
        
        if centralManager != nil{
            os_log("initialized centralManager")
        }
        
    }
    
    func closeStream(){
        centralManager.stopScan()   //stops looking for devices
        dataRecieved.removeAll(keepingCapacity: false)  //clearing BLE queue
        peripheralManager.stopAdvertising()     //this advertises to the bottle cap,,, may not need (ask josh and zane what they decide)
    }
    
    
    func connectDevice(){
        if let connectedPeripheral = connectedPeripheral{
            os_log("Connecting to peripheral %@", connectedPeripheral)
            self.connectedPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
            //deviceTableView.reloadData()      //reloads the data after you connect so you can change the type of button from connect to disconnect
            os_log("CONNECTED")
        }
        else {
            os_log("NOT CONNECTED TO PERIPHERAL")
            
        }
    }
    func disconnectDevice(){
        if let connectedPeripheral = connectedPeripheral{
            os_log("disconnecting from peripheral %@", connectedPeripheral)
            centralManager.cancelPeripheralConnection(connectedPeripheral)
            
            //deviceTableView.reloadData()      //reloads the data after you connect so you can change the type of button from connect to disconnect
            os_log("DISCONNECTED")
        }
        else {
            os_log("STILL CONNECTED TO PERIPHERAL")
            
        }
    }
    
    func scanForDevices(){
        os_log("Scanning for Devices...")
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        if centralManager.isScanning {
            os_log("is scanning")
        }
        else {
            os_log("not scanning")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        guard RSSI.intValue >= -50
        else {
            //            os_log("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
            return
        }
        
        
        //if(String(describing: peripheral.identifier) == "F8DDCC5D-D2F0-FEC9-E400-575577FC5008"){
            os_log("Discovered %s at %d with identifier %s", String(describing: peripheral.name), RSSI.intValue, String(describing: peripheral.identifier))
            os_log("%d",advertisementData.count)
            for advertisement in advertisementData{
                os_log("%s", String(describing: advertisement))
            }
        if (advertisementData["kCBAdvDataLocalName"] != nil){
            if (String(describing: advertisementData["kCBAdvDataLocalName"]!) == "BBUDDY"){
                connectedPeripheral = peripheral
                connectedPeripheral.delegate = self
                os_log("Successfully Discovered Bottle Buddy")
                central.stopScan()
            }
        }


        
       
            
       // }
        
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
       // cleanup()
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        os_log("Peripheral Connected")
        // Stop scanning
        centralManager.stopScan()
        os_log("Scanning stopped")
        
        // Clear the data that we may already have
        dataRecieved.removeAll(keepingCapacity: false)
        
        // Make sure we get the discovery callbacks
        //peripheral.delegate = self
        
        // Search only for services that match our UUID
        //peripheral.discoverServices([TransferService.serviceUUID])
        peripheral.discoverServices([mainService.serviceUUID])
        //deviceTableView.reloadData()
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        os_log("Perhiperal Disconnected")
        connectedPeripheral = nil
        //deviceTableView.reloadData()
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
            return
        case .unauthorized:
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
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            return
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
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
                sendingEOM = true
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
        os_log("entered write data function")
        
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = centralTransferCharacteristic
        else {
            os_log("returning if connected peripheral and transfer charac. did not work")
            return
        }
        
        //Makes sure we don't transfer more than we can in any given cycle
        //let mtu = connectedPeripheral.maximumWriteValueLength (for: .withoutResponse)
       
        //var rawPacket = 1
        
        
//        let bytesToCopy: size_t = min(mtu, dataRecieved.count)
        
//        dataRecieved.copyBytes(to: &rawPacket, count: bytesToCopy)
        //let packetData = Data(bytes: &rawPacket, count: 1)
//        let stringFromData = String(data: packetData, encoding: .utf8)
        
//        os_log("Writing %d bytes: %s", bytesToCopy, String(describing: stringFromData))
//        os_log("%s", String(describing: packetData))
//        connectedPeripheral.writeValue(packetData, for: transferCharacteristic, type: .withoutResponse)
//        os_log("Successfully written data")
        
        let turn_on: Bool = true;
        
        let turn_off: Bool = false;
        
        let turnOnData = withUnsafeBytes(of: turn_on) { Data($0) }
        let turnOffData = withUnsafeBytes(of: turn_off) { Data($0) }
        connectedPeripheral.writeValue(turnOnData, for: transferCharacteristic, type: .withResponse)
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for service in invalidatedServices where service.uuid == mainService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([mainService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
        }
    }
    
    
    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            //cleanup()
            return
        }
        // Discover the characteristic we want...
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        /*for service in peripheralServices {
         peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
         }*/
        
        for service in peripheralServices {
            peripheral.discoverCharacteristics([mainService.characteristicUUID], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            //cleanup()
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        /*for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
         // If it is, subscribe to it
         centralTransferCharacteristic = characteristic
         peripheral.setNotifyValue(true, for: characteristic)
         }*/
        for characteristic in serviceCharacteristics where characteristic.uuid == mainService.characteristicUUID {
            // If it is, subscribe to it
            centralTransferCharacteristic = characteristic
            //peripheral.setNotifyValue(true, for: characteristic)
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            //cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        os_log("Received %d bytes: %s", characteristicData.count, stringFromData)
        
        // Have we received the end-of-message token?
        if stringFromData == "EOM" {
            // End-of-message case: show the data.
            // Dispatch the text view update to the main queue for updating the UI, because
            // we don't know which thread this method will be called back on.
            //            DispatchQueue.main.async() {
            //                self.centralTextView.text = String(data: self.dataRecieved, encoding: .utf8)
            //            }
            
            // Write test data
            //writeData()
        } else {
            // Otherwise, just append the data to what we have previously received.
            dataRecieved.append(characteristicData)
        }
    }
    
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        //guard characteristic.uuid == TransferService.characteristicUUID else { return }
        guard characteristic.uuid == mainService.characteristicUUID else { return }
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
            //cleanup()
        }
    }
    
}
