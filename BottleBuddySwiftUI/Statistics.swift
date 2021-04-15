//
//  Statistics.swift
//  BottleBuddySwiftUI
//
//  Created by Sanika Phanse on 4/15/21.
//

import Foundation


class Statistics {
    var sevenWeekLog: Array<Int>?
    var percent: Int
    var dailyGoal: Int
    var state: AppState
    let formatter = DateFormatter()
    
    init(state: AppState){
        self.state = state
        sevenWeekLog = nil
        percent = 0
        dailyGoal  = Int(state.userData!.weight)! * 2/3
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
    }
    
    func getSevenWeekLog() -> Array<Int>?{
        self.sevenWeekLog = Array<Int>()
        
        var date = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        var i = 0
        
        while i < 7 {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            let predicate = "date == " + "'" + String(formatter.string(from: date)) + "'"
            
            var waterTotal = 0
            state.waterReadings!.filter(predicate).forEach{waterReading in
                waterTotal = waterTotal + Int(waterReading.water_level)!
            }
            self.sevenWeekLog?.append(waterTotal)
            i = i + 1
        }
        
        return self.sevenWeekLog
    }
    
    func getPercent() -> Int{
        let predicate = "date == " + "'" + String(formatter.string(from: Date())) + "'"
        var waterTotal = 0
        state.waterReadings!.filter(predicate).forEach{waterReading in
            waterTotal = waterTotal + Int(waterReading.water_level)!
        }
        
        return waterTotal / self.dailyGoal
    }
    
    func getDailyGoal() -> Int{
        return dailyGoal
    }
}
