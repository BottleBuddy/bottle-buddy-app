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
    var healthStore: HealthStore?
    var dailyTotal: Double = 0.0
    var steps2: Double = 0.0
    
    init(state: AppState){
        self.state = state
        self.healthStore = HealthStore()
        
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
    
    func getDaysLabels() -> Array<String> {
        var labels: Array<String> = Array<String>()
        
        var date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var i = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"
        
        while i < 7 {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            labels.append(dateFormatter.string(from: date))
            i = i + 1
        }
        
        return labels
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
        if let healthStore = healthStore{
            healthStore.requestAuthorization { success in
                if(success){
                    healthStore.calculateSteps{statisticsCollection in
                        if let statisticsCollection = statisticsCollection{
                            let startDate = Calendar.current.date(byAdding: .day , value: -1, to: Date())!
                            let endDate = Date()
                            
                            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics,stop) in
                                self.steps2 = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 10
                            }
                        }
                    }
                }
            }
        }
        
        return Int(steps2)
    }
}

