//
//  AppStateManager.swift
//  BottleBuddySwiftUI
//
//  Created by Sanika Phanse on 3/14/21.
//

import Foundation
import RealmSwift
import Combine
import SwiftUI
import Firebase

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
                        realm.add(userObject(uid: self.partitionValue))
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
