/*
 This code makes a simple ViewController that can allow the app to send a recieve a simple message upon connection.
 Only works once per connection; However, stays connected until user disconnects
*/
import UIKit
import CoreBluetooth
import os
import Foundation
/*  NewService
 *  Description: Creates a new service with specified characteristic(s)
 *  Usage: Make this structure whenever you want to make a new service
 */
//struct NewService{
//    var serviceUUID: CBUUID!
//    var characteristicUUID: CBUUID!
//    init(testService: String, testCharacteristic: String){
//        self.serviceUUID = CBUUID(string: testService)
//        self.characteristicUUID = CBUUID(string: testCharacteristic)
//    }
//}

class ViewController: UIViewController {
    var peripheralManager: CBPeripheralManager!
    
    //Below is the main manager that the app uses to be a central device. See CentralManagerDelegate for more details.
    var centralManager: CBCentralManager! //manages all the of the peripherals and whatnot on the phone side
    
    //Below is stores so we know which transfer characteritics we are using. This will change when we properly implement the pipeline
    var peripheralTransferCharacteristic: CBMutableCharacteristic?
    
    //Below is the central transfer characteristic. This will need to be changed when the pipeline is fully developed
    var centralTransferCharacteristic: CBCharacteristic?
    
    //Below is a variable that holds which peice of hardware we are connected to right now as peripheral device.
    var connectedCentral: CBCentral?
    
    //Below is a variable that holds which peice of hardware we are connected to right now as a central device.
    var connectedPeripheral: CBPeripheral?
    
    //Below is a varaible for the data we will actuall send not receive.
    var dataToSend = Data()
    
    //Below is a varaible for the data we will recieve, not send
    var dataRecieved = Data()
    
    //Below makes a new service. This service was made for testing and there will be a lot more services later as the pipeline is developed
    //Services are sort of like objects and characteristics are like their attributes
    //this main service will eventually be the cap as a whole
   // let mainService = NewService(testService: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961", testCharacteristic: "08590F7E-DB05-467E-8757-72F6FAEB13D4")

    
    /*  viewDidLoad
     *  Description: Defines what happens when the ViewController is loaded
     *  Usage:
     */
    //MIGHT NOT NEED THIS,,, LOOK INTO THE MANAGERS
//    override func viewDidLoad() {
//        centralManager = CBCentralManager(
//            delegate: self,
//            queue: nil,
//            options: [CBCentralManagerOptionShowPowerAlertKey: true]
//        )
//        os_log("Central Manager Sucessfully Created")
//        peripheralManager = CBPeripheralManager(
//            delegate: self,
//            queue: nil,
//            options: [CBPeripheralManagerOptionShowPowerAlertKey: true]
//        )
//        os_log("Peripheral Maanger Sucessfully Created")
//        super.viewDidLoad()
//    }
    
    /*  viewWillDisappear
     *  Description: Defines what will happen when this ViewController disappears
     *  Usage: This enables you to add this to an existing NavigationViewController or TabViewController
     */
    //will need to extract the few functions from this method bc the view will not be disappearing in swiftui
    override func viewWillDisappear(_ animated: Bool) {
        centralManager.stopScan()   //stops looking for devices (the bottle cap)
        os_log("This central has stopped scanning. No longer looking for new devices")
        dataRecieved.removeAll(keepingCapacity: false)  //clearing BLE queue
        os_log("Data Received has been removed. All remaining data was subsequently lost")
        peripheralManager.stopAdvertising()     //this advertises to the bottle cap,,, may not need (ask josh and zane what they decide)
        os_log("This peripheral has stopped advertising. No longer can be found by external devices")
        super.viewWillDisappear(animated)
    }
    
    /*  sendData
     *  Description: Standard sendData() function from Apple's Example code. Personally, I did not change anything in this function because I was just testing.
     *  Usage: Call this function to actually send the data (as a peripheral) to another device. However, the way it is sent is up to you.
     */
    
    static var sendingEOM = false   //sending end of message
    
    //sending from phone to cap
    private func sendData() {
        var sendDataIndex = 0
        //Below defines the transferCharacteristic for this transfer and immediately returns if it is null/nil
        guard let transferCharacteristic = peripheralTransferCharacteristic else {return}
        //Below checks to see if we are suppose to be sending the end of message
        if ViewController.sendingEOM {
            // send it
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // It did, so mark it as sent
                ViewController.sendingEOM = false
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
                    ViewController.sendingEOM = false
                    os_log("Sent: EOM")
                }
                return
            }
        }
    }
    
    /*  setupPeripheral
     *  Description: This sets up the app as a peripheral device
     *  Usage: We probably do not need this in the end as the bottle cap will probably be the peripheral device. However, I made functionality for it
     */
//    private func setupPeripheral() {
//        //Below defines the one of the characteristics for the service we will use. This is a CBMutable Characteristic which is different.
//        let transferCharacteristic = CBMutableCharacteristic(
//            type: mainService.characteristicUUID,
//            properties: [.notify, .writeWithoutResponse],
//            value: nil,
//            permissions: [.readable, .writeable])
//
//        //Below creates the service for the characteritics to use.
//        let transferService = CBMutableService(type: mainService.serviceUUID, primary: true)
//
//        //Below adds the characteristic(s) to the service. We are only using one so far for testing.
//        transferService.characteristics = [transferCharacteristic]
//
//        // And add it to the peripheral manager.
//        peripheralManager.add(transferService)
//
//        // Save the characteristic for later.
//        self.peripheralTransferCharacteristic = transferCharacteristic
//
//    }
    
    /*  scanForDevices
     *  Description: This makes the app scan for new peripheral devices in the area
     *  Usage: Call this where you need it. However, it might need to be changed once we add more services and characteristics
     */
    //NEED THE CENTRALMANAGER.SCANFORP,,, BUT NEED TO MOVE THIS FUNCTION CALL
    @IBAction func scanForDevices(_ sender: Any){
        os_log("Scanning for Devices...")
//        centralManager.scanForPeripherals(
//            withServices: [mainService.serviceUUID],
//            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
//        )
    }
    /*  connectToDevice
     *  Description: This establishes a connection to the specified device called "connectedPeripheral". Probably will need to change slightly if we want multiple device connections.
     *  Usage: Call this function when you need it
     */
    //WILL NEED THE CENTRALMANAGER.CONNECT,,, NEED TO MOVE THE CALL
    @IBAction func connectToDevice(_ sender: Any){
        if let connectedPeripheral = connectedPeripheral{
            os_log("Connecting to peripheral %@", connectedPeripheral)
            self.connectedPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
            //deviceTableView.reloadData()      //reloads the data after you connect so you can change the type of button from connect to disconnect
        }
    }
    
    /*  cleanUp()
     *  Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    private func cleanup() {
        // Don't do anything if we're not connected
        guard let connectedPeripheral = connectedPeripheral,
            case .connected = connectedPeripheral.state else { return }
        
        for service in (connectedPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
//                if characteristic.uuid == mainService.characteristicUUID && characteristic.isNotifying {
//                    // It is notifying, so unsubscribe
//                    self.connectedPeripheral?.setNotifyValue(false, for: characteristic)
//                }
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
    private func writeData() {
    
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

//extension ViewController: CBPeripheralManagerDelegate {
    // implementations of the CBPeripheralManagerDelegate methods

    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
//    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
//
//        advertisingSwitch.isEnabled = peripheral.state == .poweredOn
//
//        switch peripheral.state {
//        case .poweredOn:
//            // ... so start working with the peripheral
//            os_log("CBManager is powered on")
//            setupPeripheral()
//        case .poweredOff:
//            os_log("CBManager is not powered on")
//            // In a real app, you'd deal with all the states accordingly
//            return
//        case .resetting:
//            os_log("CBManager is resetting")
//            // In a real app, you'd deal with all the states accordingly
//            return
//        case .unauthorized:
//            // In a real app, you'd deal with all the states accordingly
//            if #available(iOS 13.0, *) {
//                switch peripheral.authorization {
//                case .denied:
//                    os_log("You are not authorized to use Bluetooth")
//                case .restricted:
//                    os_log("Bluetooth is restricted")
//                default:
//                    os_log("Unexpected authorization")
//                }
//            } else {
//                // Fallback on earlier versions
//            }
//            return
//        case .unknown:
//            os_log("CBManager state is unknown")
//            // In a real app, you'd deal with all the states accordingly
//            return
//        case .unsupported:
//            os_log("Bluetooth is not supported on this device")
//            // In a real app, you'd deal with all the states accordingly
//            return
//        @unknown default:
//            os_log("A previously unknown peripheral manager state occurred")
//            // In a real app, you'd deal with yet unknown cases that might occur in the future
//            return
//        }
//    }

    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
//    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
//        os_log("Central subscribed to characteristic")
//
//        // Get the data
//        dataToSend = peripheralTextView.text?.data(using: .utf8) ?? Data()
//
//        // save central
//        connectedCentral = central
//
//        // Start sending
//        sendData()
//    }
    
    /*
     *  Recognize when the central unsubscribes
     */
//    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
//        os_log("Central unsubscribed from characteristic")
//        connectedCentral = nil
//    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
//    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
//        // Start sending again
//        sendData()
//    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
//    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//        for aRequest in requests {
//            guard let requestValue = aRequest.value,
//                let stringFromData = String(data: requestValue, encoding: .utf8) else {
//                    continue
//            }
//
//            os_log("Received write request of %d bytes: %s", requestValue.count, stringFromData)
//            self.peripheralTextView.text = stringFromData
//        }
//    }
//}


//extension ViewController: UITextViewDelegate {
//    /*
//     *  Adds the 'Done' button to the title bar
//     */
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        // We need to add this manually so we have a way to dismiss the keyboard
//        let rightButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
//        navigationItem.rightBarButtonItem = rightButton
//    }
//
//    /*
//     * Finishes the editing
//     */
//    @objc
//    func dismissKeyboard() {
//        peripheralTextView.resignFirstResponder()
//        navigationItem.rightBarButtonItem = nil
//    }
//
//}

extension ViewController: CBCentralManagerDelegate {
    // implementations of the CBCentralManagerDelegate methods

    /*
     *  centralManagerDidUpdateState is a required protocol method.
     *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
     *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
     *  the Central is ready to be used.
     */
    //mostly used for debugging
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {

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
    }

    /*
     *  This callback comes whenever a peripheral that is advertising the transfer serviceUUID is discovered.
     *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
     *  we start the connection process
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        guard RSSI.intValue >= -50
            else {
                os_log("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
                return
        }
        
        os_log("Discovered %s at %d with identifier %s", String(describing: peripheral.name), RSSI.intValue, String(describing: peripheral.identifier))
        
        
            
        
        // Device is in range - have we already seen it?
        if connectedPeripheral != peripheral {
            
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
            connectedPeripheral = peripheral
            
            central.stopScan()
            //deviceTableView.reloadData()
            // And finally, connect to the peripheral.
            //os_log("Connecting to perhiperal %@", peripheral)
            //centralManager.connect(peripheral, options: nil)
        }
    }

    /*
     *  If the connection fails for whatever reason, we need to deal with it.
     */
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        os_log("Failed to connect to %@. %s", peripheral, String(describing: error))
        cleanup()
    }
    
    /*
     *  We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
     */
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
//        peripheral.discoverServices([mainService.serviceUUID])
        //deviceTableView.reloadData()
    }
    
    /*
     *  Once the disconnection happens, we need to clean up our local copy of the peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        os_log("Perhiperal Disconnected")
        connectedPeripheral = nil
        //deviceTableView.reloadData()
    }

}

//the phone is not a peripheral device so we probs dont need this but maybe
extension ViewController: CBPeripheralDelegate {
    // implementations of the CBPeripheralDelegate methods

    /*
     *  The peripheral letting us know when services have been invalidated.
     */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {

//        for service in invalidatedServices where service.uuid == mainService.serviceUUID {
//            os_log("Transfer service is invalidated - rediscover services")
//            peripheral.discoverServices([mainService.serviceUUID])//REVIEW WHAT THIS DOES BECAUSE IT DOESNT MAKE SENSE
//        }
    }

    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error discovering services: %s", error.localizedDescription)
            cleanup()
            return
        }

        // Discover the characteristic we want...

        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        /*for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }*/

        for service in peripheralServices {
//            peripheral.discoverCharacteristics([mainService.characteristicUUID], for: service)
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
            cleanup()
            return
        }

        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        /*for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            // If it is, subscribe to it
            centralTransferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }*/
//        for characteristic in serviceCharacteristics where characteristic.uuid == mainService.characteristicUUID {
//            // If it is, subscribe to it
//            centralTransferCharacteristic = characteristic
//            peripheral.setNotifyValue(true, for: characteristic)
//        }

        // Once this is complete, we just need to wait for the data to come in.
    }

    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            os_log("Error discovering characteristics: %s", error.localizedDescription)
            cleanup()
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
            writeData()
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
//        guard characteristic.uuid == mainService.characteristicUUID else { return }
        if characteristic.isNotifying {
            // Notification has started
            os_log("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            os_log("Notification stopped on %@. Disconnecting", characteristic)
            cleanup()
        }

    }
    /*  disconnectFromDevice
     *  Description: Action that disconnects from the specified device.
     *  Usage: Use as needed.
     */
    //will need to change how it connects to our new button
    @IBAction func disconnectFromDevice(_ sender: Any){
        if connectedPeripheral != nil{
            centralManager.cancelPeripheralConnection(connectedPeripheral!)
        }
    }

}

//will need to make our own tableView to display the bottle caps to connect with
//extension ViewController: UITableViewDataSource{
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//       // return connectedPeripherals?.count ?? 0
//        if connectedPeripheral != nil{
//            return 1
//        }else{
//            let noDataLabel: UILabel  = UILabel()
//            noDataLabel.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height/2)
//                    noDataLabel.text          = "No Buddies Found :("
//                    noDataLabel.textAlignment = .center
//                    //tableView.backgroundView  = noDataLabel
//                    tableView.separatorStyle  = .none
//            let findABuddyButton: UIButton = UIButton(type: .system)
//            findABuddyButton.frame = CGRect(x: 0, y: tableView.bounds.size.height/2, width: tableView.bounds.size.width, height: tableView.bounds.size.height/2)
//                    findABuddyButton.setTitle("Find A Buddy", for: .normal)
//                    findABuddyButton.addTarget(self, action: #selector(scanForDevices(_:)), for: .touchUpInside)
//            let myView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
//            myView.addSubview(noDataLabel)
//            myView.addSubview(findABuddyButton)
//            tableView.backgroundView = myView
//            return 0
//        }
//    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        // Ask for a cell of the appropriate type.
//        let cell = tableView.dequeueReusableCell(withIdentifier: "foodCellType",
//                                 for: indexPath) as! DeviceListCell
//        cell.peripheral = connectedPeripheral
//        if connectedPeripheral?.state == .connected{
//            cell.connect?.setTitle("Disconnect From \(String(describing: connectedPeripheral?.name ?? "Unknown"))'s Buddy", for: .normal)
//            cell.connect?.addTarget(self, action: #selector(disconnectFromDevice(_:)), for: .touchUpInside)
//            return cell
//        }else{
//            cell.connect?.setTitle("Connect To \(String(describing: connectedPeripheral?.name ?? "Unknown"))'s Buddy", for: .normal)
//            cell.connect?.addTarget(self, action: #selector(connectToDevice(_:)), for: .touchUpInside)
//            return cell
//        }
//    }
//}






