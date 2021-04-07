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


//writeAcknowledgement
//writeIntake
//id, volume, and timestamp

struct NewService{
    var characteristicUUIDs = [CBUUID]()
    var serviceUUID: CBUUID!
    init(service: String, numOfCharacteristics: Int){
        self.serviceUUID = CBUUID(string: service)
        for i in 1...numOfCharacteristics{
            let str = String(service.prefix(7)) + String(i) + String(service.suffix(28))
            self.characteristicUUIDs.append(CBUUID(string: str))
            os_log("%s", str)
        }
        //self.characteristicUUIDs = [CBUUID]()
    }
}

enum BLEChar: Int{
    case BottleType = 0, IntakePackage, Acknowledgement, Year, Month, Day, Hour, Minute, Second, WroteTime, DrinkWater, Clean
}

class Bluetooth: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject, Identifiable{
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    //var peripheralTransferCharacteristic: CBMutableCharacteristic?
    var centralTransferCharacteristic = [CBCharacteristic?]()
    //which piece of hardware we are connected to
    var connectedCentral: CBCentral?
    
    //what hardware is connected to right now as a central device.
    var connectedPeripheral: CBPeripheral!
    
    //data we will actuall send not receive.
    //var dataToSend = Data()
    
    //data we will recieve, not send
    var dataRecieved = Data()
    var connected = false
    @Published var waterIntakeState = UInt16()
    var configurationService = NewService(service: "19B10010-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 1)
    var waterIntakeService = NewService(service: "19B10020-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 10)
    var cleaningService = NewService(service: "19B10030-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 1)
    
    override init(){
      //  sendingEOM = false      //this is j to make things compile,, may need to change later
        super.init()
        initializeStream()
    }
    
    func initializeStream(){
        centralManager = CBCentralManager(
            
            delegate: self,
            queue: nil,
            options: nil)
        
        if centralManager != nil{
            os_log("initialized centralManager")
        }
        /*demoService.characteristicUUIDs.append(CBUUID(string: "19B10015-E8F2-537E-4F6C-D104768A1214"))//UVC
        demoService.characteristicUUIDs.append(CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214"))//TOF
        demoService.characteristicUUIDs.append(CBUUID(string: "19B10013-E8F2-537E-4F6C-D104768A1214"))////Y
        demoService.characteristicUUIDs.append(CBUUID(string: "19B10014-E8F2-537E-4F6C-D104768A1214"))//Z
        demoService.characteristicUUIDs.append(CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214"))//X*/
        
        
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
            withServices: [configurationService.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
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
        
        os_log("Discovered %s at %d with identifier %s", String(describing: peripheral.name), RSSI.intValue, String(describing: peripheral.identifier))
        if (advertisementData["kCBAdvDataLocalName"] != nil){
            if (String(describing: advertisementData["kCBAdvDataLocalName"]!) == "BBUDDY"){
                connectedPeripheral = peripheral
                connectedPeripheral.delegate = self
                os_log("Successfully Discovered Bottle Buddy")
                centralManager.connect(connectedPeripheral, options: nil)
                if (connectedPeripheral.state == .connected){
                    connected = true
                    central.stopScan()
                }else{
                    centralManager.scanForPeripherals(withServices: [configurationService.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                }
                
            }
        }
        
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
        peripheral.discoverServices([configurationService.serviceUUID])
        //deviceTableView.reloadData()
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        os_log("Perhiperal Disconnected")
        connectedPeripheral = nil
        //deviceTableView.reloadData()
        connected = false
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
               // if characteristic.uuid == demoService.characteristicUUID && characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    self.connectedPeripheral?.setNotifyValue(false, for: characteristic)
                //}
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
    func writeClean() {
        os_log("entered write clean function")
        
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = centralTransferCharacteristic[BLEChar.Clean.rawValue]
        //let transferCharacteristic = [CBUUID(string: "19B10015-E8F2-537E-4F6C-D104768A1214")]
        else {
            os_log("returning if connected peripheral and transfer charac. did not work")
            return
        }
        
        //Makes sure we don't transfer more than we can in any given cycle
        //let mtu = connectedPmaximumWriteValueLength (for: .withoutResponse)
       
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
        let turnOnData = withUnsafeBytes(of: turn_on) { Data($0) }
        connectedPeripheral.writeValue(turnOnData, for: transferCharacteristic, type: .withResponse)
    }
    
    func writeAck() {
        os_log("entered Ack data function")
        
        guard let connectedPeripheral = connectedPeripheral,
              let transferCharacteristic = centralTransferCharacteristic[BLEChar.Acknowledgement.rawValue]
        //let transferCharacteristic = [CBUUID(string: "19B10015-E8F2-537E-4F6C-D104768A1214")]
        else {
            os_log("returning if connected peripheral and transfer charac. did not work")
            return
        }
        
        
        let ack: UInt16 = 1;
        let turnOnData = withUnsafeBytes(of: ack) { Data($0) }
        connectedPeripheral.writeValue(turnOnData, for: transferCharacteristic, type: .withResponse)
    }
    
    
    func writeTimestamp() {
        os_log("entered Timestamp function")
        
        for i in 0...4{
            guard let connectedPeripheral = connectedPeripheral,
                  let transferCharacteristic = centralTransferCharacteristic[BLEChar[i].rawValue]
            //let transferCharacteristic = [CBUUID(string: "19B10015-E8F2-537E-4F6C-D104768A1214")]
            else {
                os_log("returning if connected peripheral and transfer charac. did not work")
                return
            }
            
            let today = Date()
            let formatter1 = DateFormatter()
            formatter1.dateStyle = .short
            
            
            let formatter2 = DateFormatter()
            formatter2.timeStyle = .medium
            var stringTime = formatter2.string(from: today);
            var stringDate = formatter1.string(from: today);
            var val =  UInt8(stringTime)
            
            print(stringDate)
            print(stringTime)
            let turnOnData = withUnsafeBytes(of: val) { Data($0) }
            connectedPeripheral.writeValue(turnOnData, for: centralTransferCharacteristic[BLEChar.Year.rawValue]!, type: .withResponse)
        }
      
        

    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for service in invalidatedServices where service.uuid == configurationService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([configurationService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
        }
        
        for service in invalidatedServices where service.uuid == waterIntakeService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([waterIntakeService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
        }
        
        for service in invalidatedServices where service.uuid == waterIntakeService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([waterIntakeService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
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

        
        for service in peripheralServices {
            peripheral.discoverCharacteristics(configurationService.characteristicUUIDs, for: service)
            peripheral.discoverCharacteristics(waterIntakeService.characteristicUUIDs, for: service)
            peripheral.discoverCharacteristics(cleaningService.characteristicUUIDs, for: service)
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
        
        
        for cbuuid in configurationService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        centralTransferCharacteristic.append(characteristic)
                    }
            }
        
        for cbuuid in waterIntakeService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        centralTransferCharacteristic.append(characteristic)
                    }
            }
        
        for cbuuid in cleaningService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        centralTransferCharacteristic.append(characteristic)
                    }
            }
        connected = true
        
        /*for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
         // If it is, subscribe to it
         centralTransferCharacteristic = characteristic
         peripheral.setNotifyValue(true, for: characteristic)
         }*/
        
        
        
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
        
        guard let characteristicData = characteristic.value
               else { return }
        
        let stringFromData = String(describing: characteristicData)
                
        os_log("Received %d bytes from CBUUID %s : %s", characteristicData.count, String(describing: characteristic.uuid), stringFromData)
        // Have we received the end-of-message token?
            // Otherwise, just append the data to what we have previously received.
        
        if(String(describing: characteristic.uuid) == "19B10011-E8F2-537E-4F6C-D104768A1214"){
        dataRecieved = characteristic.value!
            waterIntakeState = (UInt16(self.dataRecieved[1])<<8) + (UInt16(self.dataRecieved[0]))
            //dataRecieved[0] = characteristic.value?
            dataRecieved.removeAll()
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
        
        //guard characteristic.uuid == demoService.characteristicUUIDs else { return }
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
            //cleanup()
        }
    }
    
    
    func getTofValue()->UInt16{
        if (connectedPeripheral != nil){
            if(!centralTransferCharacteristic.isEmpty){
                connectedPeripheral.readValue(for: centralTransferCharacteristic[BLEChar.BottleType.rawValue]!)
            }
            
        }
        if(self.dataRecieved.isEmpty){
            return 0;
        }
        var result = UInt16()
        result = (UInt16(self.dataRecieved[1])<<8) + (UInt16(self.dataRecieved[0]))
        dataRecieved.removeAll()
        return result
    }
    func getIMUValue()->String{
        if (connectedPeripheral != nil){
            if(!centralTransferCharacteristic.isEmpty){
               connectedPeripheral.readValue(for: centralTransferCharacteristic[1]!)
            }
            
        }

        if(self.dataRecieved.isEmpty){
            return "";
        }
        let result = "\n X Value: \(String(data: dataRecieved, encoding: .utf8)!) \n Y Value: \(String(data: dataRecieved, encoding: .utf8)!) \n Z Value \(String(data: dataRecieved, encoding: .utf8)!)"
        return result
    }
}
