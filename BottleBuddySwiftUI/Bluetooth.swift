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


class Bluetooth: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject, Identifiable{
    var notification = NotificationManager()
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral!
    @Published var connected = false
    var group = DispatchGroup()
    var waterIntake_ID = UInt16()
    var oldWaterIntakeID = UInt16(0)
    var waterIntake_Timestamp_Date = UInt32()
    var waterIntake_Timestamp_Time = UInt32()
    var waterIntake_Heights = UInt32()
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
    var characteristicsMap = [CBUUID : CBCharacteristic]()
    var finished_cleaning = Bool()
    
    let Callibration_Service_CBUUID = CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")
    let Callibration_Date_CBUUID = CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214")
    let Callibration_Time_CBUUID = CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214")
    let Callibration_WroteTime_CBUUID = CBUUID(string: "19B10013-E8F2-537E-4F6C-D104768A1214")
    //Recieve from BB
    let WaterIntake_Service_CBUUID = CBUUID(string: "19B10020-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_ID_CBUUID = CBUUID(string: "19B10021-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_RecieveDate_CBUUID = CBUUID(string: "19B10022-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_RecieveTime_CBUUID = CBUUID(string: "19B10023-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_Heights_CBUUID = CBUUID(string: "19B10024-E8F2-537E-4F6C-D104768A1214")
    //Send to BB
    let WaterIntake_Ack_CBUUID = CBUUID(string: "19B10025-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_SendDate_CBUUID = CBUUID(string: "19B10026-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_SendTime_CBUUID = CBUUID(string: "19B10027-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_WroteTime_CBUUID = CBUUID(string: "19B10028-E8F2-537E-4F6C-D104768A1214")
    let WaterIntake_DrinkWater_CBUUID = CBUUID(string: "19B10029-E8F2-537E-4F6C-D104768A1214")
    //Cleaning Service
    let Cleaning_Service_CBUUID = CBUUID(string: "19B10030-E8F2-537E-4F6C-D104768A1214")
    let Cleaning_StartClean_CBUUID = CBUUID(string: "19B10031-E8F2-537E-4F6C-D104768A1214")
    let Cleaning_FinishedClean_CBUUID = CBUUID(string: "19B10032-E8F2-537E-4F6C-D104768A1214")
    //Debug
    let Cleaning_Debug_CBUUID = CBUUID(string: "19B10033-E8F2-537E-4F6C-D104768A1214")
    
    var state: AppState? = nil
    
    override init(){
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: nil)
        if centralManager != nil{os_log("initialized centralManager")}
    }
    func setState(state: AppState){self.state = state}
    func connectDevice(){
        if let connectedPeripheral = connectedPeripheral{
            os_log("Connecting To: %@", connectedPeripheral)
            self.connectedPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
            if(oldWaterIntakeID != waterIntake_ID){connectedPeripheral.readValue(for: characteristicsMap[WaterIntake_ID_CBUUID]!)}
        }
        else {os_log("Unable to Connect")}
    }
    func disconnectDevice(){
        if let connectedPeripheral = connectedPeripheral{
            os_log("Disconnecting From: %@", connectedPeripheral)
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        else {os_log("Did Not Disconnet")}
    }
    func scanForDevices(){
        os_log("Looking for a buddy...")
        centralManager.scanForPeripherals(
            withServices: [Callibration_Service_CBUUID, WaterIntake_Service_CBUUID, Cleaning_Service_CBUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        if centralManager.isScanning {os_log("is scanning")}
        else {os_log("not scanning")}
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue >= -50
        else {return}
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
                }
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Peripheral Connected")
        centralManager.stopScan()
        os_log("Scanning stopped")
        peripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("Perhiperal Disconnected")
        connectedPeripheral = nil
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
        case .unauthorized:
            os_log("Unauthorized")
        @unknown default:
            os_log("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214"){
            os_log("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices(nil)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            return
        }
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        guard let serviceCharacteristics = service.characteristics else { return }
            for characteristic in serviceCharacteristics {
                characteristicsMap.updateValue(characteristic, forKey: characteristic.uuid)
                os_log("Added characteristic: %@", characteristic)
                connectedPeripheral.setNotifyValue(true, for: characteristic)
            }
        connected = true
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        guard let characteristicData = characteristic.value
        else { return }
        
        let stringFromData = String(describing: characteristicData)
        os_log("Received %d bytes from CBUUID %s : %s", characteristicData.count, String(describing: characteristic.uuid), stringFromData)
        
        if(String(describing: characteristic.uuid) == "19B10021-E8F2-537E-4F6C-D104768A1214"){
            oldWaterIntakeID = waterIntake_ID
            let waterIntake_ID_data = characteristic.value!
            waterIntake_ID = UInt16((waterIntake_ID_data[1])<<8) + UInt16((waterIntake_ID_data[0]))
            connectedPeripheral.readValue(for: characteristicsMap[WaterIntake_RecieveDate_CBUUID]!)
            connectedPeripheral.readValue(for: characteristicsMap[WaterIntake_RecieveTime_CBUUID]!)
            connectedPeripheral.readValue(for: characteristicsMap[WaterIntake_Heights_CBUUID]!)
        }
        if(String(describing: characteristic.uuid) == "19B10022-E8F2-537E-4F6C-D104768A1214"){
            let waterIntake_Timestamp_Date_Data = characteristic.value!
            day = UInt8(waterIntake_Timestamp_Date_Data[0])
            month = UInt8(waterIntake_Timestamp_Date_Data[1])
            year = (UInt16(waterIntake_Timestamp_Date_Data[3])<<8) | UInt16(waterIntake_Timestamp_Date_Data[2])
            readWaterIntakeDate = true
        }
        if(String(describing: characteristic.uuid) == "19B10023-E8F2-537E-4F6C-D104768A1214"){
            let waterIntake_Timestamp_Time_Data = characteristic.value!
            hour =  waterIntake_Timestamp_Time_Data[2]
            minute = waterIntake_Timestamp_Time_Data[1]
            second = waterIntake_Timestamp_Time_Data[0]
            readWaterIntakeTime = true
        }
        if(String(describing: characteristic.uuid) == "19B10024-E8F2-537E-4F6C-D104768A1214"){
            let waterIntake_Heights_Data = characteristic.value!
            oldHeightData = waterIntake_Heights_Data[2]
            newHeightData = waterIntake_Heights_Data[0]
            readWaterIntakeHeightsBool = true
        }
        if(String(describing: characteristic.uuid) == "19B10032-E8F2-537E-4F6C-D104768A1214"){
            let cleaning_finished_data = characteristic.value!
            finished_cleaning = (cleaning_finished_data[0] != 0)
            finishedClean(cleaningFinished: finished_cleaning)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            os_log("Error changing notification state: %s", error.localizedDescription)
            return
        }
        if characteristic.isNotifying {
            os_log("Notification began on %@", characteristic)
        } else {
            os_log("Notification stopped on %@. Disconnecting", characteristic)
        }
    }
    func addWaterReading(date: String, time: String, waterHeights: [Int]) {
        let waterDrank = convertHeightMMtoVolumeOZ(height: waterHeights[0]) - convertHeightMMtoVolumeOZ(height: waterHeights[1])
        let newDrank = Int(waterDrank - 0.5)
        var finalWater = 0
        if(Int(waterDrank) == newDrank){finalWater = Int(waterDrank)+1}
        else{finalWater = Int(waterDrank)}
        let newWaterReading = waterReading(water_level: String(describing: finalWater))
        
        newWaterReading.date = date
        newWaterReading.time = time
    
        guard let realm =  state!.waterReadings!.realm else {
            state!.waterReadings!.append(newWaterReading)
            return
        }
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
        
        if(day<10){dayString = "0"+"\(day)"}
        else{dayString = "\(day)"}
        
        if(month<10){monthString = "0"+"\(month)"}
        else{monthString = "\(month)"}
        
        var finalString = String()
        finalString = dayString+"-"+monthString+"-\(year)"
        print("final date for Database input: ", finalString)
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

        let dateArr = formatter.string(from: now).split(separator: "-")
        var day: Int = Int(dateArr[0])!
        let month : Int = Int(dateArr[1])!
        let year : Int = Int(dateArr[2])!
        var dayBinary = String(day, radix: 2)
        var monthBinary = String(month, radix: 2)
        var yearBinary = String(year, radix: 2)
        
        
        for i in Range(0...(8-dayBinary.count-1)){dayBinary = "0"+dayBinary}
        for i in Range(0...(8-monthBinary.count-1)){monthBinary = "0"+monthBinary
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
        for _ in Range(0...(8-hourBinary.count-1)){
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
        let heightArr = [Int(oldHeight),Int(newHeight)]
        print("Height Array: "+"\(heightArr[0]) "+"\(heightArr[1])")
        return heightArr
    }
    func sendCallibrationService(){
        sendUInt32(data: sendCurrentDateUInt(), cbuuid: Callibration_Date_CBUUID) //writiing to callibration date
        os_log("writing to callibration date")
        sendUInt32(data: sendCurrentTimeUInt(),cbuuid: Callibration_Time_CBUUID) //writiing to callibration time
        os_log("writing to callibration time")
       sendBoolean(boolVal: true, cbuuid: Callibration_WroteTime_CBUUID) //writiing to callibration wrote time
            self.notification.sendNotification(title: "Callibration Done!", subtitle: nil, body: "Your Bottle is ready for use", launchIn: 1)
        os_log("writing to callibration wrote time")
    }
    func sendBoolean(boolVal : Bool, cbuuid : CBUUID){
        os_log("entered send Boolean function")
        guard let connectedPeripheral = connectedPeripheral else {return}
        let boolData = withUnsafeBytes(of: boolVal) { Data($0) }
        connectedPeripheral.writeValue(boolData, for: characteristicsMap[cbuuid]!, type: .withResponse)
    }
    func sendUInt32(data : UInt32, cbuuid: CBUUID)->CBUUID{
        os_log("entered send UInt32 function")
        guard let connectedPeripheral = connectedPeripheral else {return CBUUID(string: "")}
        let finalData = withUnsafeBytes(of: data) { Data($0) }
        connectedPeripheral.writeValue(finalData, for: characteristicsMap[cbuuid]!, type: .withResponse)
        return cbuuid
    }
    func sendUInt16(data : UInt16, cbuuid: CBUUID)->CBUUID{
        os_log("entered send Date function")
        guard let connectedPeripheral = connectedPeripheral else {return CBUUID(string: "")}
        let finalData = withUnsafeBytes(of: data) { Data($0) }
        connectedPeripheral.writeValue(finalData, for: characteristicsMap[cbuuid]!, type: .withResponse)
        return cbuuid
    }
    func startBottleClean() {
        os_log("Trying to Clean Bottle")
        sendBoolean(boolVal: true, cbuuid: Cleaning_StartClean_CBUUID) //tell bottle to clean
    }
    func finishedClean(cleaningFinished : Bool)->Bool{
        if(cleaningFinished){
            self.notification.sendNotification(title: "Cleaning Done!", subtitle: nil, body: "Go enjoy some water :).", launchIn: 1)
        }
        return cleaningFinished
    }
    func createWaterIntakeResponse(waterIntakePackageID : UInt16){
        sendUInt16(data: waterIntakePackageID, cbuuid: WaterIntake_Ack_CBUUID) //acknowledged water package
    }
    func recurringWaterIntakeTimestamp(){
        sendUInt32(data: sendCurrentDateUInt(), cbuuid: WaterIntake_SendDate_CBUUID) //writing to water Intake date
        sendUInt32(data: sendCurrentTimeUInt(), cbuuid: WaterIntake_SendTime_CBUUID) //writiing to water Intake time
        sendBoolean(boolVal: true, cbuuid: WaterIntake_WroteTime_CBUUID) // write to water package wrote time
    }
    func drinkWater() ->Bool{
        sendBoolean(boolVal: true, cbuuid: WaterIntake_DrinkWater_CBUUID)
        return true
    }
}
