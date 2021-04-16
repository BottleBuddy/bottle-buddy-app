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
    var tofValue = Data()
    @Published var numTOF = UInt16()
    var lastTOF = UInt16()
    
    var waterIntake_ID_data = Data()
    var waterIntake_ID = UInt16()
    var waterIntake_Timestamp_Date_Data = Data()
    var waterIntake_Timestamp_Time_Data = Data()
    var waterIntake_Timestamp_Date = UInt32()
    var waterIntake_Timestamp_Time = UInt32()
    
    var waterIntake_Heights_Data = Data()
    var waterIntake_Heights = UInt32()
    var recieved_acknowledgement = Data()
    var calibration_Timestamp_Date_Data = Data()
    var calibration_Timestamp_Time = Data()
    var calibration_WroteTime = Data()
    var DrinkWater = Data()
    var cleaning_start = Data()
    var cleaning_finished_data = Data()
    
    //Actual one you read... Should we make this published?
    var finished_cleaning = Bool()
    
    
    var state: AppState? = nil
   
    
    var calibrationService = NewService(service: "19B10010-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 3)
    var waterIntakeService = NewService(service: "19B10020-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 9)
    var cleaningService = NewService(service: "19B10030-E8F2-537E-4F6C-D104768A1214", numOfCharacteristics: 2)
 
    


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
            withServices: [waterIntakeService.serviceUUID, cleaningService.serviceUUID, calibrationService.serviceUUID],
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
                    centralManager.scanForPeripherals(withServices: [waterIntakeService.serviceUUID, cleaningService.serviceUUID, calibrationService.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
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
        peripheral.discoverServices([waterIntakeService.serviceUUID, cleaningService.serviceUUID, calibrationService.serviceUUID])
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
        
    
        for service in invalidatedServices where ((service.uuid == waterIntakeService.serviceUUID) || (service.uuid == cleaningService.serviceUUID) || (service.uuid == calibrationService.serviceUUID)){
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([waterIntakeService.serviceUUID, cleaningService.serviceUUID, calibrationService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
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
            peripheral.discoverCharacteristics(waterIntakeService.characteristicUUIDs, for: service)
            peripheral.discoverCharacteristics(cleaningService.characteristicUUIDs, for: service)
            peripheral.discoverCharacteristics(calibrationService.characteristicUUIDs, for: service)
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
        
        for cbuuid in calibrationService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        // If it is, subscribe to it
                    os_log("adding %@", String(describing: characteristic.uuid))
                        centralTransferCharacteristic.append(characteristic)
                        connectedPeripheral.setNotifyValue(true, for: characteristic)
                    }
            }
        
        for cbuuid in waterIntakeService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        // If it is, subscribe to it
                    os_log("adding %@", String(describing: characteristic.uuid))
                        centralTransferCharacteristic.append(characteristic)
                        connectedPeripheral.setNotifyValue(true, for: characteristic)
                    }
            }
        
        for cbuuid in cleaningService.characteristicUUIDs {
                for characteristic in serviceCharacteristics where characteristic.uuid == cbuuid {
                        // If it is, subscribe to it
                    os_log("adding %@", String(describing: characteristic.uuid))
                        centralTransferCharacteristic.append(characteristic)
                        connectedPeripheral.setNotifyValue(true, for: characteristic)
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
            waterIntake_ID_data = characteristic.value!
            waterIntake_ID = UInt16(waterIntake_ID_data[1]<<8) + UInt16(waterIntake_ID_data[0])
            connectedPeripheral.readValue(for: centralTransferCharacteristic[4]!)//date
            connectedPeripheral.readValue(for: centralTransferCharacteristic[5]!)//time
            connectedPeripheral.readValue(for: centralTransferCharacteristic[6]!)//height
            addWaterReading(date: convertDateForDB(date: waterIntake_Timestamp_Date), time: convertTimeForDB(time: waterIntake_Timestamp_Date), waterHeights: convertHeighToInt(heights: waterIntake_Heights))
            createWaterIntakeResponse(waterIntakePackageID : waterIntake_ID)//send ID ack
            
            
        }
        
        if(String(describing: characteristic.uuid) == "19B10022-E8F2-537E-4F6C-D104768A1214"){
            waterIntake_Timestamp_Date_Data = characteristic.value!
            waterIntake_Timestamp_Date = UInt32((waterIntake_Timestamp_Date_Data[3]<<24) + (waterIntake_Timestamp_Date_Data[2]<<16))
            waterIntake_Timestamp_Date +=  UInt32((waterIntake_Timestamp_Date_Data[1]<<8) + (waterIntake_Timestamp_Date_Data[0]))
            
        }
        if(String(describing: characteristic.uuid) == "19B10023-E8F2-537E-4F6C-D104768A1214"){
            waterIntake_Timestamp_Time_Data = characteristic.value!
            waterIntake_Timestamp_Time = UInt32((waterIntake_Timestamp_Time_Data[3]<<24) + (waterIntake_Timestamp_Time_Data[2]<<16))
            waterIntake_Timestamp_Time += UInt32((waterIntake_Timestamp_Time_Data[1]<<8) + (waterIntake_Timestamp_Time_Data[0]))
            
        }
        
        if(String(describing: characteristic.uuid) == "19B10024-E8F2-537E-4F6C-D104768A1214"){
            waterIntake_Heights_Data = characteristic.value!
            waterIntake_Heights = UInt32((waterIntake_Heights_Data[3]<<24) + (waterIntake_Heights_Data[2]<<16))
            waterIntake_Heights += UInt32((waterIntake_Heights_Data[1]<<8) + (waterIntake_Heights_Data[0]))
            
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
        let newWaterReadingOld = waterReading(water_level: String(describing: tofValue))

        newWaterReadingOld.date = date
        newWaterReadingOld.time = time
        
        
        let newWaterReadingNew = waterReading(water_level: String(describing: tofValue))

        newWaterReadingNew.date = date
        newWaterReadingNew.time = time
        
        
        guard let realm = state!.waterReadings!.realm else {
            state!.waterReadings!.append(newWaterReadingOld)
            state!.waterReadings!.append(newWaterReadingNew)
            
            return
        }
        try! realm.write {
            state!.waterReadings!.append(newWaterReadingOld)
            state!.waterReadings!.append(newWaterReadingNew)
        }
        
         
    }
    
    
    
    func convertDateForDB(date : UInt32) -> String {
         var dateNum = String(date)
        let dateString = String(Int(dateNum)!, radix: 2)
        
//        var year = dateTimeString.substring(from: String.index(8), to: String.index(16))
       print(dateString)
        var start = dateString.index(dateString.startIndex, offsetBy: 0)
        var end = dateString.index(dateString.endIndex, offsetBy: -16)
        var range = start..<end
        let year = dateString[range]
        print(year)
        let yearNum = Int(year, radix: 2)!
        print(yearNum)


        start = dateString.index(dateString.endIndex, offsetBy: -17)
        end = dateString.index(dateString.endIndex, offsetBy: -9)
        range = start..<end
        let month = dateString[range]
        print(month)
        let monthNum = Int(month, radix: 2)!
        print(monthNum)
        
        
        start = dateString.index(dateString.endIndex, offsetBy: -8)
        end = dateString.index(dateString.endIndex, offsetBy: 0)
        range = start..<end
        let day = dateString[range]
        print(day)
        let dayNum = Int(day, radix: 2)!
        print(dayNum)
        
        
        var finalString = String()
        finalString = String(describing: dayNum)+"-"+String(describing: monthNum)+"-"+String(describing: yearNum)
//
        print("final: ", finalString) // Output: 25
        return finalString
        
    }
    
    func convertTimeForDB(time : UInt32) -> String {
         var timeNum = String(time)
        let timeString = String(Int(timeNum)!, radix: 2)

//        var year = dateTimeString.substring(from: String.index(8), to: String.index(16))
       print(timeString)
        var start = timeString.index(timeString.startIndex, offsetBy: 0)
        var end = timeString.index(timeString.endIndex, offsetBy: -16)
        var range = start..<end
        let hour = timeString[range]
        print(hour)
        let hourNum = Int(hour, radix: 2)!
        print(hourNum)


        start = timeString.index(timeString.endIndex, offsetBy: -17)
        end = timeString.index(timeString.endIndex, offsetBy: -9)
        range = start..<end
        let min = timeString[range]
        print(min)
        let minNum = Int(min, radix: 2)!
        print(minNum)


        start = timeString.index(timeString.endIndex, offsetBy: -8)
        end = timeString.index(timeString.endIndex, offsetBy: 0)
        range = start..<end
        let second = timeString[range]
        print(second)
        let secondNum = Int(second, radix: 2)!
        print(secondNum)


        var finalString = String()
        finalString = String(describing: hourNum)+":"+String(describing: minNum)+":"+String(describing: secondNum)
        print("final: ", finalString) // Output: 25
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
        finalTimeString = "00000000"+hourBinary+secondBinary+minBinary
        print(finalTimeString.count)
        
        var timeAnswer = UInt32(finalTimeString, radix: 2)!
        print(timeAnswer)
        return timeAnswer
        
    }
    
    
    
    func convertHeighToInt(heights : UInt32) -> [Int] {
        
        var heightbin = String(heights)
        heightbin = String(Int(heightbin)!, radix: 2)
        print("heightBinary", heightbin)
        
        var start = heightbin.index(heightbin.startIndex, offsetBy: 0)
        var index = heightbin.index(heightbin.startIndex, offsetBy: 16)
        let oldHeight = heightbin[start..<index]
        
        index = heightbin.index(heightbin.endIndex, offsetBy: -16 )
        let newHeight = heightbin[index...]
        
        var oldHeightNumber = Int(oldHeight, radix: 2)!
        var newHeightNumber = Int(newHeight, radix: 2)!
        var heightArr = [oldHeightNumber,newHeightNumber]
        //var finalString = String(describing: oldHeightNumber)+"-" + String(describing: newHeightNumber)

        return heightArr
        
    }
    
    //Calibration Functions
    func sendCallibrationService(){
        sendUInt32(data: sendCurrentDateUInt(), index: 0) //writiing to callibration date
        os_log("writing to callibration date")
        sendUInt32(data: sendCurrentTimeUInt(), index: 1) //writiing to callibration time
        os_log("writing to callibration time")
        sendBoolean(boolVal: true, index: 2) //writiing to callibration wrote time
        
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
        guard let connectedPeripheral = connectedPeripheral else {return -1}
        
        let finalData = withUnsafeBytes(of: data) { Data($0) }
      connectedPeripheral.writeValue(finalData, for: centralTransferCharacteristic[index]!, type: .withResponse)
        os_log("%s %s", data, index)
        return index

        
    }
    
    func sendUInt16(data : UInt16, index: Int)->Int{
        os_log("entered send Date function")
        guard let connectedPeripheral = connectedPeripheral else {return -1}
        
        let finalData = withUnsafeBytes(of: data) { Data($0) }
      connectedPeripheral.writeValue(finalData, for: centralTransferCharacteristic[index]!, type: .withResponse)
        os_log("%s %s", data, index)
        
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
            notification.sendNotification(title: "Cleaning Done!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 1)
        }
        else{
            //send cleaning was unsuccessful
            notification.sendNotification(title: "Cleaning Not Done!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 1)
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
