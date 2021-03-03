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

struct WaterReadingView : View {
    @EnvironmentObject var state: AppState
    
    var body: some View {
        ZStack {
            if let waterReadings = state.waterReadings {
                waterReadingsView(waterReadings: waterReadings)
                    .disabled(state.shouldIndicateActivity)
            }
            // If the app is doing work in the background,
            // overlay an ActivityIndicator
            if state.shouldIndicateActivity {
                ActivityIndicator().environmentObject(state)
            }
        }
    }
}

struct WaterReadingView_Previews: PreviewProvider {
    static var previews: some View {
        WaterReadingView()
    }
}

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

// MARK: State Objects

/// State object for managing App flow.
/// As applications grow, this object may have to be broken out further.
class AppState: ObservableObject {
    /// Publisher that monitors log in state.
    var loginPublisher = PassthroughSubject<RealmSwift.User, Error>()
    /// Publisher that monitors log out state.
    var logoutPublisher = PassthroughSubject<Void, Error>()
    /// Cancellables to be retained for any Future.
    var cancellables = Set<AnyCancellable>()
    /// Whether or not the app is active in the background.
    @Published var shouldIndicateActivity = false
    /// The list of waterReadings in the first group in the realm that will be displayed to the user.
    @Published var waterReadings: RealmSwift.List<waterReading>?
    
    @Published var userData: userObject?
    
    var partitionValue: String = Auth.auth().currentUser!.uid
    var email: String = Auth.auth().currentUser!.email!
    
    init() {
        // Create a private subject for the opened realm, so that:
        // - if we are not using Realm Sync, we can open the realm immediately.
        // - if we are using Realm Sync, we can open the realm later after login.
        let realmPublisher = PassthroughSubject<Realm, Error>()
        // Specify what to do when the realm opens, regardless of whether
        // we're authenticated and using Realm Sync or not.
        realmPublisher
            .sink(receiveCompletion: { result in
                // Check for failure.
                if case let .failure(error) = result {
                    print("Failed to log in and open realm: \(error.localizedDescription)")
                }
            }, receiveValue: { realm in
                // The realm has successfully opened.
                // If no group has been created for this app, create one.
                if realm.objects(WaterReadingsGroup.self).count == 0 {
                    try! realm.write {
                        realm.add(WaterReadingsGroup())
                    }
                }
                assert(realm.objects(WaterReadingsGroup.self).count > 0)
                self.waterReadings = realm.objects(WaterReadingsGroup.self).first!.waterReadings
                
                
                if realm.objects(userObject.self).count == 0 {
                    try! realm.write {
                        realm.add(userObject(uid: self.partitionValue, email: self.email, name: displayName))
                    }
                }
                
                assert(realm.objects(userObject.self).count > 0)
                self.userData = realm.objects(userObject.self).first!
            })
            .store(in: &cancellables)

        // MARK: Realm Sync Use Case

        // Monitor login state and open a realm on login.
        loginPublisher
            .receive(on: DispatchQueue.main) // Ensure we update UI elements on the main thread.
            .flatMap { realm_user -> RealmPublishers.AsyncOpenPublisher in
                // Logged in, now open the realm.

                // We want to chain the login to the opening of the realm.
                // flatMap() takes a result and returns a different Publisher.
                // In this case, flatMap() takes the user result from the login
                // and returns the realm asyncOpen's result publisher for further
                // processing.

                // We use "SharedPartition" as the partition value so that all users of this app
                // can see the same data. If we used the user.id, we could store data per user.
                // However, with anonymous authentication, that user.id changes upon logout and login,
                // so we will not see the same data or be able to sync across devices.
                
                let configuration = realm_user.configuration(partitionValue: Auth.auth().currentUser!.uid)

                // Loading may take a moment, so indicate activity.
                self.shouldIndicateActivity = true

                // Open the realm and return its publisher to continue the chain.
                return Realm.asyncOpen(configuration: configuration)
            }
            .receive(on: DispatchQueue.main) // Ensure we update UI elements on the main thread.
            .map { // For each realm result, whether successful or not, always stop indicating activity.
                self.shouldIndicateActivity = false // Stop indicating activity.
                return $0 // Forward the result as-is to the next stage.
            }
            .subscribe(realmPublisher) // Forward the opened realm to the handler we set up earlier.
            .store(in: &self.cancellables)

        // Monitor logout state and unset the waterReadings list on logout.
        logoutPublisher.receive(on: DispatchQueue.main).sink(receiveCompletion: { _ in }, receiveValue: { _ in
                self.waterReadings = nil
            }).store(in: &cancellables)

        // If we already have a current user from a previous app
        // session, announce it to the world.
        if let realm_user = app?.currentUser {
            loginPublisher.send(realm_user)
        }
    }
}

// MARK: waterReading Views
/// The screen containing a list of waterReadings in a group. Implements functionality for adding, rearranging,
/// and deleting waterReadings in the group.
struct waterReadingsView: View {
    /// The waterReadings in this group.
    @ObservedObject var waterReadings: RealmSwift.List<waterReading>

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
                    ForEach(waterReadings.freeze()) { frozenwaterReading in
                        // "Thaw" the waterReading before passing it in, as waterReadingRow
                        // may want to edit it, and cannot do so on a frozen object.
                        // This is a convenient place to thaw because we have access
                        // to the unfrozen realm via the waterReadings list.
                        waterReadingRow(waterReading: waterReadings.realm!.resolve(ThreadSafeReference(to: frozenwaterReading))!)
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
        
        guard let realm = waterReadings.realm else {
            waterReadings.append(newWaterReading)
            return
        }
        try! realm.write {
            waterReadings.append(newWaterReading)
        }
    }

    /// Deletes the given waterReading.
    func delete(at offsets: IndexSet) {
        guard let realm = waterReadings.realm else {
            waterReadings.remove(at: offsets.first!)
            return
        }
        try! realm.write {
            realm.delete(waterReadings[offsets.first!])
        }
    }

    /// Rearranges the given waterReading in the group.
    /// This is persisted because the waterReadings are stored in a Realm List.
    func move(fromOffsets offsets: IndexSet, toOffset to: Int) {
        guard let realm = waterReadings.realm else {
            waterReadings.move(fromOffsets: offsets, toOffset: to)
            return
        }
        try! realm.write {
            waterReadings.move(fromOffsets: offsets, toOffset: to)
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

// MARK: General View
/// Simple activity indicator to telegraph that the app is active in the background.
struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        return UIActivityIndicatorView(style: .large)
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        (uiView as! UIActivityIndicatorView).startAnimating()
    }
}

