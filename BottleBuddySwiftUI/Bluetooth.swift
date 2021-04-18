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
import RealmSwift


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
    var allCharacteristics = [CBUUID]()
    var notification = NotificationManager()
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    //var peripheralTransferCharacteristic: CBMutableCharacteristic?
    var centralTransferCharacteristic = [CBCharacteristic?]()
    var connectedCentral: CBCentral?
    //what hardware is connected to right now as a central device.
    var connectedPeripheral: CBPeripheral!
    
    //data we will recieve, not send
    var dataRecieved = Data()
    @Published var connected = false
    var tofValue = Data()
    @Published var numTOF = UInt16()
    var lastTOF = UInt16()
    
    var group = DispatchGroup()
    var waterIntake_ID_data = Data()
    var waterIntake_ID = UInt16()
    var oldWaterIntakeID = UInt16(0)
    var waterIntake_Timestamp_Date_Data = Data()
    var waterIntake_Timestamp_Time_Data = Data()
    var waterIntake_Timestamp_Date = UInt32()
    var waterIntake_Timestamp_Time = UInt32()
    var waterIntake_Heights_Data = Data()
    var waterIntake_Heights = UInt32()
    var recieved_acknowledgement = Data()
    var readWaterIntakeHeightsBool = Bool()
    var readWaterIntakeDate = Bool()
    var readWaterIntakeTime = Bool()
    var day = UInt8(0)
    var month = UInt8(0)
    var year = UInt16(0)
    var hour = UInt8(0)
    var minute = UInt8(0)
    var second = UInt8(0)
    var oldHeightData = UInt8(0)
    var newHeightData = UInt8(0)
    var calibration_Timestamp_Date_Data = Data()
    var calibration_Timestamp_Time = Data()
    var calibration_WroteTime = Data()
    
    var cleaning_start = Data()
    var cleaning_finished_data = Data()
    
    var DrinkWater = Data()
    
    //Actual one you read... Should we make this published?
    var finished_cleaning = Bool()
    
    
    var state: AppState? = nil
    
    
    //var calibrationService = NewService(service: "19B10010-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 3)
   // var waterIntakeService = NewService(service: "19B10020-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 9)
    //var cleaningService = NewService(service: "19B10030-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 2)
    
    
    
    
    
    
    
    
    
    override init(){
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: nil)
        
        if centralManager != nil{
            os_log("initialized centralManager")
        }
        
    
    }
    
    func setState(state: AppState){
        self.state = state
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
            //read new WaterIntake ID if necessary
            if(oldWaterIntakeID != waterIntake_ID){
                connectedPeripheral.readValue(for: centralTransferCharacteristic[3]!)
            }
            
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
            withServices: [CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214"), CBUUID(string: "19B10020-E8F2-537E-4F6C-D104768A1214"), CBUUID(string: "19B10030-E8F2-537E-4F6C-D104768A1214")],
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
                }/*else{
                    centralManager.scanForPeripherals(withServices: [CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
                }*/
                
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
        allCharacteristics.append(CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10013-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10021-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10022-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10023-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10024-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10025-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10027-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10028-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10029-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10031-E8F2-537E-4F6C-D104768A1214"))
        allCharacteristics.append(CBUUID(string: "19B10032-E8F2-537E-4F6C-D104768A1214"))
        // Search only for services that match our UUID
        //peripheral.discoverServices([TransferService.serviceUUID])
        os_log("SHOULD BE EMPTY: %@",[peripheral.services])
        peripheral.discoverServices(nil)
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
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        
        for service in invalidatedServices where service.uuid == CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214"){
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices(nil)//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
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
        
        
        os_log("Peripheral Services are: %@", peripheralServices)
        os_log("SHOULD HAVE SOMETHING: %@", [peripheral.services])
        
        //for service in peripheralServices {
            
        //os_log("Current Service is: %@", service)
            //var serviceCharacteristics = service.characteristics
            //os_log("Current Characteristics are: %@ ", serviceCharacteristics)
        for n in (1...4) {
            peripheral.discoverCharacteristics(nil, for: peripheralServices[0])
        }
        
            //peripheral.discoverCharacteristics(waterIntakeService.characteristicUUIDs, for: service)
            //peripheral.discoverCharacteristics(cleaningService.characteristicUUIDs, for: service)
            
        //}
        
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
        os_log("Service is: %@", service)
        os_log("Service Characteristics are: %@", service.characteristics!)
        //os_log("Characteristics Searching for: %@", allCharacteristics)
        
        //for cbuuid in calibrationService.characteristicUUIDs {
            //os_log("Calibration Service Characteristics are: %@", calibrationService.characteristicUUIDs)
            for characteristic in serviceCharacteristics {
                // If it is, subscribe to it
                //os_log("adding %@", String(describing: characteristic.uuid))
                centralTransferCharacteristic.append(characteristic)
               // os_log("characteristic adding is: %@", characteristic)
                connectedPeripheral.setNotifyValue(true, for: characteristic)
            }
            // }
        
        //os_log("%@", centralTransferCharacteristic)
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
        
        
        /*if(TOF_ORIGINAL_FUNCTION){
         tofValue = characteristic.value!
         lastTOF = (UInt16(tofValue[1])<<8) + (UInt16(tofValue[0]))
         if(250 < lastTOF && lastTOF < 260){
         numTOF = lastTOF
         //addWaterReading(tofValues: numTOF)
         }
         //call addwaterReading
         //call createWaterIntakeResponse
         
         //
         }*/
        os_log("Received %d bytes from CBUUID %s : %s", characteristicData.count, String(describing: characteristic.uuid), stringFromData)
        
        //We are reading this from josh
        /*if(String(describing: characteristic.uuid) == "19B10011-E8F2-537E-4F6C-D104768A1214"){
         calibration_Timestamp_Date_Data = characteristic.value!
         calibration_Timestamp_Date_Year = calibration_Timestamp_Date_Data[2]
         calibration_Timestamp_Date_Month = calibration_Timestamp_Date_Data[1]
         calibration_Timestamp_Date_Day = calibration_Timestamp_Date_Data[0]
         }*/
        
        //We are reading this from josh
        /*if(String(describing: characteristic.uuid) == "19B10012-E8F2-537E-4F6C-D104768A1214"){
         calibration_Timestamp_Time_Data = characteristic.value!
         calibration_Timestamp_Time_Year = calibration_Timestamp_Date_Data[2]
         calibration_Timestamp_Time_Month = calibration_Timestamp_Date_Data[1]
         calibration_Timestamp_Time_Day = calibration_Timestamp_Date_Data[0]
         }*/
        
        /*if(String(describing: characteristic.uuid) == "19B10013-E8F2-537E-4F6C-D104768A1214"){
         waterIntake_Timestamp_Time = characteristic.value!
         
         }*/
        
        
        if(String(describing: characteristic.uuid) == "19B10021-E8F2-537E-4F6C-D104768A1214"){
            oldWaterIntakeID = waterIntake_ID
            waterIntake_ID_data = characteristic.value!
            waterIntake_ID = UInt16((waterIntake_ID_data[1])<<8) + UInt16((waterIntake_ID_data[0]))
            
            connectedPeripheral.readValue(for: centralTransferCharacteristic[4]!)
            
            connectedPeripheral.readValue(for: centralTransferCharacteristic[5]!)
            
            connectedPeripheral.readValue(for: centralTransferCharacteristic[6]!)
            
            //            self.readWaterIntakeDatestamp(group : group)
            //            self.readWaterIntakeTimestamp(group : group)
            //            self.readWaterIntakeHeights(group : group)
            
            //group.wait()
            
            
            //            var waterDate = self.convertDateForDB(day: self.day,month: self.month,year: self.year)
            //            var waterTime = self.convertTimeForDB(hour: self.hour, minute: self.minute, second: self.second)
            //            var waterHeights = self.convertHeightToInt(oldHeight: self.oldHeightData, newHeight: self.newHeightData )
            //            self.addWaterReading(date: waterDate,time: waterTime, waterHeights: waterHeights )
            //            self.createWaterIntakeResponse(waterIntakePackageID : self.waterIntake_ID)//send ID ack
            //                    print("Done with one water reading")
            
//            var waterDate = self.convertDateForDB(day: self.day,month: self.month,year: self.year)
//            var waterTime = self.convertTimeForDB(hour: self.hour, minute: self.minute, second: self.second)
//            var waterHeights = self.convertHeightToInt(oldHeight: self.oldHeightData, newHeight: self.newHeightData )
//            self.addWaterReading(date: waterDate,time: waterTime, waterHeights: waterHeights )
//            print("Done with one water reading")
//            self.createWaterIntakeResponse(waterIntakePackageID : self.waterIntake_ID)//send ID ack
            
            
            
        }
        
        if(String(describing: characteristic.uuid) == "19B10022-E8F2-537E-4F6C-D104768A1214"){
            waterIntake_Timestamp_Date_Data = characteristic.value!
            //            let time1 = (UInt32(waterIntake_Timestamp_Date_Data[3])<<24) + (UInt32(waterIntake_Timestamp_Date_Data[2])<<16)
            //            let time2 =  (UInt32(waterIntake_Timestamp_Date_Data[1])<<8) + UInt32(waterIntake_Timestamp_Date_Data[0])
            day = UInt8(waterIntake_Timestamp_Date_Data[0])
            month = UInt8(waterIntake_Timestamp_Date_Data[1])
            year = (UInt16(waterIntake_Timestamp_Date_Data[3])<<8) | UInt16(waterIntake_Timestamp_Date_Data[2])
            //            waterIntake_Timestamp_Date = time1 + time2
            readWaterIntakeDate = true
            waterIntake_Timestamp_Date_Data = Data()
           
            
        }
        if(String(describing: characteristic.uuid) == "19B10023-E8F2-537E-4F6C-D104768A1214"){
            waterIntake_Timestamp_Time_Data = characteristic.value!
            hour =  waterIntake_Timestamp_Time_Data[2]
            minute = waterIntake_Timestamp_Time_Data[1]
            second = waterIntake_Timestamp_Time_Data[0]
            
            readWaterIntakeTime = true
         
        }
        
        if(String(describing: characteristic.uuid) == "19B10024-E8F2-537E-4F6C-D104768A1214"){
            waterIntake_Heights_Data = characteristic.value!
            oldHeightData = waterIntake_Heights_Data[2]
            newHeightData = waterIntake_Heights_Data[0]
            readWaterIntakeHeightsBool = true
            
           
            
        }
        
        
        if(String(describing: characteristic.uuid) == "19B10032-E8F2-537E-4F6C-D104768A1214"){
            cleaning_finished_data = characteristic.value!
            finished_cleaning = (cleaning_finished_data[0] != 0)
            finishedClean(cleaningFinished: finished_cleaning)
        }
        
        
        dataRecieved.append(characteristicData)
        
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
    
    func addWaterReading(date: String, time: String, waterHeights: [Int]) {
        
        let oldVol = convertHeightMMtoVolumeOZ(height: waterHeights[0])
        let newVol = convertHeightMMtoVolumeOZ(height: waterHeights[1])
        var waterDrank = oldVol - newVol
        let newDrank = Int(waterDrank - 0.5)
        var finalWater = 0
        
        if(Int(waterDrank) == newDrank){
            finalWater = Int(waterDrank)+1
        }
        else{
            finalWater = Int(waterDrank)
        }
        
        let newWaterReading = waterReading(water_level: String(describing: finalWater))
        
        newWaterReading.date = date
        newWaterReading.time = time
        
        
        
        // let threadSafeReference = ThreadSafeReference(to: newWaterReading)
        
        guard let realm =  state!.waterReadings!.realm else {
            state!.waterReadings!.append(newWaterReading)
            
            
            return
        }
        // let object = realm.resolve(threadSafeReference)!
        try! realm.write {
            state!.waterReadings!.append(newWaterReading)
            
        }
        
        self.notification.sendNotification(title: "Water Reading Added!", subtitle: nil, body: "You just Drank \(finalWater) oz", launchIn: 1)
        print("Add water reading done")
    }
    
    func convertHeightMMtoVolumeOZ(height : Int)->Double{
        let smallRadius = 38.1
        let largeRadius = 44.45
        let pi = 3.14159
        let bottleHeight = 164
        let inflectionPoint = 90
        let ozConversion = 0.000033814022558919
        
        var volumeMM3 = 0.0
        if (height >= inflectionPoint){
            volumeMM3 = pi * smallRadius * smallRadius * Double(bottleHeight - height)
        } else {
            let smallCylinder = pi * smallRadius * smallRadius * Double(bottleHeight - inflectionPoint)
            volumeMM3 = (pi * largeRadius * largeRadius * Double(inflectionPoint - height)) + smallCylinder
        }
        return volumeMM3 * ozConversion
    }
    
    
    
    func convertDateForDB(day :UInt8, month :UInt8, year : UInt16) -> String {
        
        var dayString = ""
        var monthString = ""
        if(day<10){
             dayString = "0"+"\(day)"
        }
        else{
            dayString = "\(day)"
        }
        if(month<10){
             monthString = "0"+"\(month)"
        }
        else{
            monthString = "\(month)"
        }
       
        var finalString = String()
        finalString = dayString+"-"+monthString+"-\(year)"
        //
        print("final date for Database input: ", finalString) // Output: 25
        return finalString
        
    }
    
    func convertTimeForDB(hour: UInt8, minute : UInt8, second :UInt8) -> String {
        var minString = ""
        var secString = ""
        var hourString = ""
        if(minute<10){
             minString = "0"+"\(minute)"
        }
        else{
            minString = "\(minute)"
        }
        if(second<10){
             secString = "0"+"\(second)"
        }
        else{
            secString = "\(second)"
        }
        if(hour<10){
             hourString = "0"+"\(hour)"
        }
        else{
            hourString = "\(hour)"
        }
        
        var finalString = String()
        
        finalString = hourString+":"+minString+":"+secString
        print("final time for Database input: ", finalString) // Output: 25
        return finalString
        
    }
    
    
    func sendCurrentDateUInt() -> UInt32 {
        
        var finalDateString = String()
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        var date =  formatter.string(from: now)
        print(date)
        
        var dateArr = date.split(separator: "-")
        var day: Int = Int(dateArr[0])!
        let month : Int = Int(dateArr[1])!
        let year : Int = Int(dateArr[2])!
        var dayBinary = String(day, radix: 2)
        var monthBinary = String(month, radix: 2)
        var yearBinary = String(year, radix: 2)
        
        
        for i in Range(0...(8-dayBinary.count-1)){
            dayBinary = "0"+dayBinary
        }
        for i in Range(0...(8-monthBinary.count-1)){
            monthBinary = "0"+monthBinary
        }
        
        for i in Range(0...(16-yearBinary.count-1)){
            yearBinary = "0"+yearBinary
        }
        print("day", dayBinary)
        print("month", monthBinary)
        print("year", yearBinary)
        finalDateString = yearBinary+monthBinary+dayBinary
        print(finalDateString.count)
        
        var dateAnswer = UInt32(finalDateString, radix: 2)!
        print("current date in UInt32: ", dateAnswer)
        return dateAnswer
        
    }
    
    func sendCurrentTimeUInt() -> UInt32 {
        var finalTimeString = String()
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "HH:mm:ss"
        var time = formatter.string(from: now)
        print(time)
        
        var timeArr = time.split(separator: ":")
        var hour: Int = Int(timeArr[0])!
        let min : Int = Int(timeArr[1])!
        let second : Int = Int(timeArr[2])!
        var hourBinary = String(hour, radix: 2)
        var minBinary = String(min, radix: 2)
        var secondBinary = String(second, radix: 2)
        
        
        
        for i in Range(0...(8-hourBinary.count-1)){
            hourBinary = "0"+hourBinary
        }
        for i in Range(0...(8-minBinary.count-1)){
            minBinary = "0"+minBinary
        }
        
        for i in Range(0...(8-secondBinary.count-1)){
            secondBinary = "0"+secondBinary
        }
        print("hour", hourBinary)
        print("min", minBinary)
        print("second", secondBinary)
        finalTimeString = "00000000"+hourBinary+minBinary+secondBinary
        print(finalTimeString.count)
        
        var timeAnswer = UInt32(finalTimeString, radix: 2)!
        print("current time in UInt32: ", timeAnswer)
        return timeAnswer
        
    }
    
    
    
    func convertHeightToInt(oldHeight : UInt8, newHeight :UInt8) -> [Int] {
        
        //        var heightbin = String(heights)
        //        heightbin = String(Int(heightbin)!, radix: 2)
        //        print("heightBinary", heightbin)
        //
        //        var start = heightbin.index(heightbin.startIndex, offsetBy: 0)
        //        var index = heightbin.index(heightbin.startIndex, offsetBy: 16)
        //        let oldHeight = heightbin[start..<index]
        //
        //        index = heightbin.index(heightbin.endIndex, offsetBy: -16 )
        //        let newHeight = heightbin[index...]
        //
        //        var oldHeightNumber = Int(oldHeight, radix: 2)!
        //        var newHeightNumber = Int(newHeight, radix: 2)!
        var heightArr = [Int(oldHeight),Int(newHeight)]
        //var finalString = String(describing: oldHeightNumber)+"-" + String(describing: newHeightNumber)
        print("Height Array: "+"\(heightArr[0]) "+"\(heightArr[1])")
        return heightArr
        
    }
    
    //Calibration Functions
    func sendCallibrationService(){
        sendUInt32(data: sendCurrentDateUInt(), index: 0) //writiing to callibration date
        os_log("writing to callibration date")
        sendUInt32(data: sendCurrentTimeUInt(), index: 1) //writiing to callibration time
        os_log("writing to callibration time")
        sendBoolean(boolVal: true, index: 2) //writiing to callibration wrote time
        
        
        
            //send notif cleaning done
            self.notification.sendNotification(title: "Callibration Done!", subtitle: nil, body: "Your Bottle is ready for use", launchIn: 1)
       
        
        os_log("writing to callibration wrote time")
        
    }
    
    func sendBoolean(boolVal : Bool, index : Int){
        os_log("entered send Boolean function")
        
        guard let connectedPeripheral = connectedPeripheral else {return}
        
        
        let boolData = withUnsafeBytes(of: boolVal) { Data($0) }
        connectedPeripheral.writeValue(boolData, for: centralTransferCharacteristic[index]!, type: .withResponse)
    }
    
    func sendUInt32(data : UInt32, index: Int)->Int{
        os_log("entered send UInt32 function")
        //os_log("%s %s", data, index)
        guard let connectedPeripheral = connectedPeripheral else {return -1}
        
        let finalData = withUnsafeBytes(of: data) { Data($0) }
        connectedPeripheral.writeValue(finalData, for: centralTransferCharacteristic[index]!, type: .withResponse)
        
        return index
        
        
    }
    
    func sendUInt16(data : UInt16, index: Int)->Int{
        os_log("entered send Date function")
        guard let connectedPeripheral = connectedPeripheral else {return -1}
        os_log("%s %s", String(data), String(index))
        let finalData = withUnsafeBytes(of: data) { Data($0) }
        connectedPeripheral.writeValue(finalData, for: centralTransferCharacteristic[index]!, type: .withResponse)
        
        
        return index
    }
    
    
    
    
    func startBottleClean() {
        os_log("Trying to Clean Bottle")
        sendBoolean(boolVal: true, index: 12) //tell bottle to clean
    }
    
    
    
    
    //Do we need this if we convert right when we get the data?
    func finishedClean(cleaningFinished : Bool)->Bool{
        //send notification
        if(cleaningFinished){
            //send notif cleaning done
            self.notification.sendNotification(title: "Cleaning Done!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 1)
        }
        else{
            //send cleaning was unsuccessful
            self.notification.sendNotification(title: "Cleaning Not Done!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 1)
        }
        
        return cleaningFinished
    }
    
    
    func createWaterIntakeResponse(waterIntakePackageID : UInt16){
        //write Date to characteristic
        
        sendUInt16(data: waterIntakePackageID, index: 7) //acknowledged water package
        
    }
    func recurringWaterIntakeTimestamp(){
        sendUInt32(data: sendCurrentDateUInt(), index: 8) //writing to water Intake date
        sendUInt32(data: sendCurrentTimeUInt(), index: 9) //writiing to water Intake time
        sendBoolean(boolVal: true, index: 10) // write to water package wrote time
    }
    func drinkWater() ->Bool{
        sendBoolean(boolVal: true, index: 11)
        return true
    }


}

