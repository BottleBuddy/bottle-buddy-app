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

struct NewService{
    var characteristicUUIDs = [CBUUID]()
    var serviceUUID = CBUUID()
    init(service: String, numOfCharacteristics: Int){
        self.serviceUUID = CBUUID(string: service)
        for i in 1...numOfCharacteristics{
            let newCharacteristic = String(service.prefix(7)) + String(format:"%01X", i) + String(service.suffix(28))
            self.characteristicUUIDs.append(CBUUID(string: newCharacteristic))
            os_log("Successfully created characteristic: %s", newCharacteristic)
        }
        
    }
}

class Bluetooth: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject, Identifiable{
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    //var peripheralTransferCharacteristic: CBMutableCharacteristic?
    var centralTransferCharacteristic = [CBCharacteristic?]()
    var connectedCentral: CBCentral?
    //what hardware is connected to right now as a central device.
    var connectedPeripheral: CBPeripheral!
    
    //data we will recieve, not send
    var dataRecieved = Data()
    var connected = false
   /* var tofValue = Data()
    var IMUxValue = Data()
    var IMUyValue = Data()
    var IMUzValue = Data()*/
    var allServices = [NewService]()
    var cleaningService = NewService(service: "19B10030-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 1)
    var waterIntakeService = NewService(service: "19B10020-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 10)
    var configurationService = NewService(service: "19B10010-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 1)


    override init(){
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: nil)
        
        if centralManager != nil{
            os_log("initialized centralManager")
        }
        allServices.append(configurationService)
        allServices.append(waterIntakeService)
        allServices.append(cleaningService)
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
            withServices: [configurationService.serviceUUID, waterIntakeService.serviceUUID, cleaningService.serviceUUID],
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
        peripheral.discoverServices([configurationService.serviceUUID, waterIntakeService.serviceUUID, cleaningService.serviceUUID])
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
                    //self.connectedPeripheral?.setNotifyValue(false, for: characteristic)
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
        os_log("entered write data function")
        
        /*guard let connectedPeripheral = connectedPeripheral,
            let transferCharacteristic = centralTransferCharacteristic[0]
        //let transferCharacteristic = [CBUUID(string: "19B10015-E8F2-537E-4F6C-D104768A1214")]
        else {
            os_log("returning if connected peripheral and transfer charac. did not work")
            return
        }*/
        
        guard let connectedPeripheral = connectedPeripheral else {return}
        
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
        
        let clean: Bool = true;
        
        let cleanData = withUnsafeBytes(of: clean) { Data($0) }
        connectedPeripheral.writeValue(cleanData, for: centralTransferCharacteristic[11]!, type: .withResponse)
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for mainService in allServices{
        for service in invalidatedServices where service.uuid == mainService.serviceUUID {
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([mainService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
        }
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

        for mainService in allServices{
        for service in peripheralServices {
            peripheral.discoverCharacteristics(mainService.characteristicUUIDs, for: service)
           // peripheral.discoverCharacteristics([demoService.characteristicArray[2]], for: service)
        }
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
        
        for mainService in allServices{
        for cbuuid in mainService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        // If it is, subscribe to it
                        centralTransferCharacteristic.append(characteristic)
                        //connectedPeripheral.setNotifyValue(true, for: characteristic)
                    }
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
           // dataRecieved.append(characteristicData)
        dataRecieved.append(characteristic.value!)
        
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
                connectedPeripheral.readValue(for: centralTransferCharacteristic[1]!)
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
        dataRecieved.removeAll()
        return result
    }
    
    
    func getOrientation()->String{
        if (connectedPeripheral != nil){
            if(!centralTransferCharacteristic.isEmpty){
                connectedPeripheral.readValue(for: centralTransferCharacteristic[1]!)
            }
            
        }

        if(self.dataRecieved.isEmpty){
            return "";
        }
        let result = "\n Pitch Value: \(String(data: dataRecieved, encoding: .utf8)!) \n Yaw Value: \(String(data: dataRecieved, encoding: .utf8)!) \n Roll Value \(String(data: dataRecieved, encoding: .utf8)!)"
        dataRecieved.removeAll()
        return result
    }
}
