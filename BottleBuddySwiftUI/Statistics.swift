//
//  Statistics.swift
//  BottleBuddySwiftUI
//
//  Created by Sanika Phanse on 4/15/21.
//

import Foundation


class Statistics {
    var sevenDayLog: Array<Int>?
    var baseGoal: Int
    var state: AppState
    let formatter = DateFormatter()
    var totalGoal: Int
    
    init(state: AppState){
        self.state = state
        sevenDayLog = nil
        if(state.userData!.weight == "") {
            baseGoal = 80
        } else {
            baseGoal  = Int(state.userData!.weight)! * 2/3
        }
        totalGoal = baseGoal
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
    }
    
    func getSevenDayLog() -> Array<Int>?{
        self.sevenDayLog = Array<Int>()
        
        var date = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        var i = 0
        
        while i < 7 {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            let predicate = "date == " + "'" + String(formatter.string(from: date)) + "'"
            
            var waterTotal = 0
            state.waterReadings!.filter(predicate).forEach{waterReading in
                waterTotal = waterTotal + Int(waterReading.water_level)!
            }
            self.sevenDayLog?.append(waterTotal)
            i = i + 1
        }
        
        return self.sevenDayLog
    }
    
    func getPercent() -> Int {
        let predicate = "date == " + "'" + String(formatter.string(from: Date())) + "'"
        var waterTotal = 0
        state.waterReadings!.filter(predicate).forEach{waterReading in
            waterTotal = waterTotal + Int(waterReading.water_level)!
        }
        return Int(Double(waterTotal) / Double(self.totalGoal) * 100)
    }
    
    func getTotalGoal() -> Int{
        if(state.userData!.weight != "") {
            baseGoal  = Int(state.userData!.weight)! * 2/3
            totalGoal = baseGoal
        }
        return totalGoal
    }
}
