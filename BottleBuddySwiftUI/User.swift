//
//  User.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/10/20.
//

import Foundation
import SwiftUI

class User: ObservableObject{
    var id: Int = 0
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    let age: Int = 0
    let birthdate: Date = Date()
    let sex: Int = 0
    let height: Int = 0
    let weight: Int = 0
    
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
