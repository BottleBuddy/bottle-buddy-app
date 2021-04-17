//
//  Statistics.swift
//  BottleBuddySwiftUI
//
//  Created by Sanika Phanse on 4/15/21.
//

import Foundation
import HealthKit

class Statistics {
    var sevenDayLog: Array<Int>? = nil
    var baseGoal: Int
    var state: AppState
    let formatter = DateFormatter()
    var totalGoal: Int
    let healthStore: HealthStore? = HealthStore()
    var dailyTotal: Double = 0.0
    
    init(state: AppState){
        self.state = state
        
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
        
        var date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
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
    
    func getDailyTotal() -> Double {
        let predicate = "date == " + "'" + String(formatter.string(from: Date())) + "'"
        self.dailyTotal = 0.0
        state.waterReadings!.filter(predicate).forEach{waterReading in
            self.dailyTotal = self.dailyTotal + Double(waterReading.water_level)!
        }
        
        return self.dailyTotal
    }
    
    func getPercent() -> Double {
        return getDailyTotal() / Double(getTotalGoal())
    }
    
    func getTotalGoal() -> Int{
        if(state.userData!.weight != "") {
            baseGoal  = Int(state.userData!.weight)! * 2/3
            totalGoal = baseGoal
        } else {
            baseGoal = 80
            totalGoal = 80
        }
        
        let steps = numSteps()
        
        if(steps >= 5000 && steps < 8000){
            totalGoal += 5
        } else if (steps >= 8000 && steps < 10000){
            totalGoal += 10
        } else if(steps >= 10000){
            totalGoal += 15
        }
        
        return totalGoal
    }
    
    func numSteps() -> Int{
        let steps: Double = self.healthStore!.calculateSteps()
        
//        self.healthStore?.requestAuthorization { success in
//            if(success){
//                self.healthStore?.calculateSteps{statisticsCollection in
//                    if let statisticsCollection = statisticsCollection{
//                        print(statisticsCollection)
//                        let data = statisticsCollection.statistics(for: Date())
//                        let count = data?.sumQuantity()?.doubleValue(for: .count())
//                        steps = Int(count ?? 0)
//                    }
//                }
//            }
        //}
        return Int(steps)
    }
}

