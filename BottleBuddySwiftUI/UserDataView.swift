//
//  HomeModel.swift
//  Backend
//
//  Created by Sanika Phanse on 10/13/20.
//  Copyright © 2020 Sanika Phanse. All rights reserved.
//

import Foundation
import Combine
import SwiftUI


//TODO: move most of this data to the home page and the profile page
struct UserDataView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var user: User
    var body: some View {
        WaterReadingView().environmentObject(user).environmentObject(state)
    }
}

struct UserDataView_Previews: PreviewProvider {
    static var previews: some View {
        UserDataView()
    }
}

