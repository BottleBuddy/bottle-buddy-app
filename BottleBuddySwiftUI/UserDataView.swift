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
    @ObservedObject var fetcher = UserDataFetcher()
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    
    
    var body: some View {
            
        List(fetcher.users) { user in
            VStack (alignment: .leading) {
                Text("First Name: " + user.firstName)
                Text("Last Name: " + user.lastName)
                Text("Age:" + user.age)
                Text("Gender: " + user.gender)
                Text("Height: " + user.height)
                Text("Weight: " + user.weight)
                Text("")
                    .font(.system(size: 15))
                    
            }
            .background(Color(bblightblue!).ignoresSafeArea())
        }
        .background(Color(bblightblue!).ignoresSafeArea())
               
    }
    
    
}

public class UserDataFetcher: ObservableObject {

    @Published var users = [UserStruct]()
    
    init(){
        print("loading url")
        load()
        print("loading url complete")
    }
    
    func load() {
        let url = URL(string: "http://3.135.94.168/index2.php")!
        
        print("url: ", url)
    
        URLSession.shared.dataTask(with: url) {(data,response,error) in
            do {
                if let d = data {
                    let decodedLists = try JSONDecoder().decode([UserStruct].self, from: d)
                    print("decoded lists: ", decodedLists)
                    DispatchQueue.main.async {
                        self.users = decodedLists
                    }
                }else {
                    print("No Data")
                }
            } catch {
                print (error)
            }
            
        }.resume()
         
    }
}

struct UserStruct: Codable, Identifiable {
    
    public var id: String
    public var firstName: String
    public var lastName: String
    public var age: String
    public var gender: String
    public var height: String
    public var weight: String
    
    enum CodingKeys: String, CodingKey {
           case id = "user_id"
           case firstName = "first_name"
           case lastName = "last_name"
           case age = "age"
           case gender = "gender"
           case height = "height"
           case weight = "weight"
        }
}
