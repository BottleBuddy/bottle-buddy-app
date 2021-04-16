//
//  AboutView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 4/10/21.
//

import SwiftUI

struct AboutView: View {
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    var body: some View {
        ScrollView{
            Text("About the Developers")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("We are a group of Electrical and Computer Engineering seniors from UT Austin. Our passion for health, fitness, and technology resulted in the BottleBuddy!")
                .foregroundColor(.white)
                .padding(.vertical)
            GridView(profileData: profileData)
        }
        .background(Color(bblightblue!).ignoresSafeArea())
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

struct GridView: View {
    var profileData: [Profile]
    var columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 30) {
            ForEach(profileData){profile in
                ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
                    VStack(alignment: .leading, spacing: 20){
                        Text(profile.name)
                            .bold()
                        Text(profile.info)
                        Image(profile.image)
                            .scaledToFit()
                            .padding()
                            .clipShape(Rectangle())
                    }
                    
                }
                .padding()
                .background(Color(bbyellow!))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x:0, y:5)
                
            }
        }
        .padding(.horizontal)
        .padding(.top, 25)
    }
    
}

struct Profile: Identifiable {
    var id: Int
    var name: String
    var info: String
    var image: String
}

var profileData = [
    Profile(id: 0, name: "Flannery", info: "Front-end", image: "flan"),
    Profile(id: 1, name: "Zane", info: "Hardware", image: "zane"),
    Profile(id: 2, name: "Josh", info: "Embedded", image: "josh"),
    Profile(id: 3, name: "Sanika", info: "Back-end", image: "sanika"),
    Profile(id: 4, name: "Jason", info: "Hardware", image: "chris"),
    Profile(id: 5, name: "Chris", info: "Embedded", image: "chris")
]
