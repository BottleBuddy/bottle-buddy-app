//  User.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/10/20.
//

import Foundation
import SwiftUI
import Combine

class User: ObservableObject{
    @Published var uid: String = ""
    var firstName: String = ""
    var lastName: String = ""
    let age: Int = 0
    let birthdate: Date = Date()
    let sex: Int = 0
    let height: Int = 0
    let weight: Int = 0
    
    init(uid: String) {
        self.uid = uid
    }
    
    init(uid: String, firstName: String, lastName: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
    }
    
    //firebase authentication state
//    enum FBAuthState{
//        case undefined, signedOut, signedIn
//    }
//    @Published var isUserAuthenticated: FBAuthState = .undefined
    
    
//    func configureFirebaseStateDidChange(){
//        self.isUserAuthenticated = .signedOut
//        self.isUserAuthenticated = .signedIn
//    }
    
}

struct User_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
