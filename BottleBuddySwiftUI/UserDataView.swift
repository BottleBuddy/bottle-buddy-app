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

struct UserDataView: View {
    @ObservedObject var fetcher = UserDataFetcher()
    
    var body: some View {
        VStack {
            List(fetcher.users) { user in
                VStack (alignment: .leading) {
                    Text(user.firstName)
                    Text(user.lastName)
                    Text(user.age)
                    Text(user.gender)
                    Text(user.height)
                    Text(user.weight)
                    Text("")
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray)
                }
            }
        }
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
