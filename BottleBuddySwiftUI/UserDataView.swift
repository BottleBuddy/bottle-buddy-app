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
    @ObservedObject var fetcher = HomeModel()
    
    var body: some View {
        VStack {
            List(fetcher.usersArray) { user in
                VStack (alignment: .leading) {
                    Text(user.firstName)
                    Text(user.lastName)
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray)
                }
            }
        }
    }
}

public class HomeModel: ObservableObject {
    
    @Published var usersArray = [User]()
    
    func getItems() {
        
        //access webpoint
        let serviceURL = "http://3.135.94.168/index2.php"
        
        //Download json data
        let url = URL(string: serviceURL)
        
        //url is not nil
        if let url = url {
            //Create url session
            let session = URLSession(configuration: .default)
            
            let task = session.dataTask(with: url, completionHandler:
            { (data, response, error) in
                if error == nil {
                    self.usersArray = self.parseJson(data!)
                } else {
                    print("URL Session Error")
                }
            })
            
            //start task
            task.resume()
        }
        
        //Notify view controller and pass the data
    }

    
    func parseJson(_ data:Data) -> [User]{

        var usersArray = [User]()

        //parse data into AccountHolderModel struct

        do {
            let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as! [Any]

            //Iterate through jsonArray and create AccountHolder struct instances
            //TODO: Change struct to class

            for jsonResult in jsonArray {

                //Cast json result as dictionary
                let jsonDict = jsonResult as! [String:String]

                let user = User(
                    id: jsonDict["user_id"]!,
                    firstName: jsonDict["firstname"]!,
                    lastName: jsonDict["lastname"]!)

                usersArray.append(user)
            }
            
            return usersArray

        } catch {
            print("There was an error")
        }
        
        return usersArray

    }
}
