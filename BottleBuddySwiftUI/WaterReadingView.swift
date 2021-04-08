//
//  WaterReadingView.swift
//  BottleBuddySwiftUI
//
//  Created by Sanika Phanse on 2/10/21.

import Foundation
import RealmSwift
import Combine
import SwiftUI
import Firebase

/// An individual reading. Part of a `WaterReadingsGroup`.
final class waterReading: Object, ObjectKeyIdentifiable {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var user_id: String = ""
    @objc dynamic var time: String = "12:00"
    @objc dynamic var date: String = "01-01-2021"
    @objc dynamic var water_level: String = ""
    /// The backlink to the `Group` this waterReading is a part of.
    let wrgroup = LinkingObjects(fromType: WaterReadingsGroup.self, property: "waterReadings")

    convenience init(water_level: String){
        self.init()
        self.water_level = water_level
        self.user_id = Auth.auth().currentUser!.uid
    }

    override static func primaryKey() -> String? {
        return "_id"
    }
}

/// Represents a collection of waterReadings.
final class WaterReadingsGroup: Object, ObjectKeyIdentifiable {
    @objc dynamic var _id = ObjectId.generate()
    let waterReadings = RealmSwift.List<waterReading>()

    override class func primaryKey() -> String? {
        "_id"
    }
}

// MARK: waterReading Views
/// The screen containing a list of waterReadings in a group. Implements functionality for adding, rearranging,
/// and deleting waterReadings in the group.
struct waterReadingsView: View {
    /// The waterReadings in this group.
    @EnvironmentObject var bluetooth: Bluetooth
    @EnvironmentObject var state: AppState
    /// The button to be displayed on the top left.
    var leadingBarButton: AnyView?

    var body: some View {
        NavigationView {
            VStack {
                // The list shows the waterReadings in the realm.
           
                List {
                    // ⚠️ ALWAYS freeze a Realm list while iterating in a SwiftUI
                    // View's ForEach(). Otherwise, unexpected behavior will occur,
                    // especially when deleting object from the list.
                    ForEach(state.waterReadings!.freeze()) { frozenwaterReading in
                        // "Thaw" the waterReading before passing it in, as waterReadingRow
                        // may want to edit it, and cannot do so on a frozen object.
                        // This is a convenient place to thaw because we have access
                        // to the unfrozen realm via the waterReadings list.
                        waterReadingRow(waterReading: state.waterReadings!.realm!.resolve(ThreadSafeReference(to: frozenwaterReading))!)
                    }.onDelete(perform: delete)
                        .onMove(perform: move)
                }.listStyle(GroupedListStyle())
                    .navigationBarTitle("waterReadings", displayMode: .large)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(
                        leading: self.leadingBarButton,
                        // Edit button on the right to enable rearranging waterReadings
                        trailing: EditButton())

                // Action bar at bottom contains Add button.
                HStack {
                    Spacer()
                    Button(action: addWaterReading) { Image(systemName: "plus") }
                }.padding()
            }
        }
    }

    func addWaterReading() {
        let newWaterReading = waterReading(water_level: "50")
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        newWaterReading.date = formatter.string(from: now)
        
        formatter.dateFormat = "HH:mm:ss"
        newWaterReading.time = formatter.string(from: now)
        
        guard let realm = state.waterReadings!.realm else {
            state.waterReadings!.append(newWaterReading)
            return
        }
        try! realm.write {
            state.waterReadings!.append(newWaterReading)
        }
    }

    
    func addWaterReadingTOF() {
        let newWaterReading = waterReading(water_level: String(bluetooth.getTofValue()))
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        newWaterReading.date = formatter.string(from: now)
        
        formatter.dateFormat = "HH:mm:ss"
        newWaterReading.time = formatter.string(from: now)
        
        guard let realm = state.waterReadings!.realm else {
            state.waterReadings!.append(newWaterReading)
            return
        }
        try! realm.write {
            state.waterReadings!.append(newWaterReading)
        }
    }

    /// Deletes the given waterReading.
    func delete(at offsets: IndexSet) {
        guard let realm = state.waterReadings!.realm else {
            state.waterReadings!.remove(at: offsets.first!)
            return
        }
        try! realm.write {
            realm.delete(state.waterReadings![offsets.first!])
        }
    }

    /// Rearranges the given waterReading in the group.
    /// This is persisted because the waterReadings are stored in a Realm List.
    func move(fromOffsets offsets: IndexSet, toOffset to: Int) {
        guard let realm = state.waterReadings!.realm else {
            state.waterReadings!.move(fromOffsets: offsets, toOffset: to)
            return
        }
        try! realm.write {
            state.waterReadings!.move(fromOffsets: offsets, toOffset: to)
        }
    }
}

/// Represents an waterReading in a list.
struct waterReadingRow: View {
    var waterReading: waterReading
    var body: some View {
        // You can click an waterReading in the list to navigate to an edit details screen.
        NavigationLink(destination: waterReadingDetailsView(waterReading)) {
            Text(waterReading.user_id)
            Text(waterReading.date)
            Text(waterReading.time)
            Text(waterReading.water_level)
        }
    }
}

struct waterReadingDetailsView: View {
    var waterReading: waterReading

    // ⚠️ Beware using a Realm object or its properties directly in a @Binding.
    // Writes to Realm objects MUST occur in a transaction (realm.write() block),
    // but a default Binding will not do that for you. Therefore, either use a
    // separate @State object to hold the data before writing (as we do here),
    // or create a custom Binding that handles writes in a transaction.
    @State var newWaterLevel: String = ""

    init(_ waterReading: waterReading) {
        // Ensure the waterReading was thawed before passing in
        assert(!waterReading.isFrozen)
        self.waterReading = waterReading
        self.newWaterLevel = waterReading.water_level
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter a new water level:")
            // Write the new name to the newwaterReadingName state variable.
            // On commit, call our commit() function.
            TextField(waterReading.water_level, text: $newWaterLevel, onCommit: { self.commit() })
                .navigationBarTitle(waterReading.water_level)
        }.padding()
    }

    /// Writes the given name to the realm in a transaction.
    private func commit() {
        guard let realm = waterReading.realm else {
            waterReading.water_level = newWaterLevel
            return
        }
        try! realm.write {
            waterReading.water_level = newWaterLevel
        }
    }
}

