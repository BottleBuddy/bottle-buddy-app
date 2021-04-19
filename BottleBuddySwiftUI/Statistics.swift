//
//  Statistics.swift
//  BottleBuddySwiftUI
//
//  Created by Sanika Phanse on 4/15/21.
//

import Foundation
import HealthKit

class Statistics {
    private var sevenDayLog: Array<Double>? = nil
    private var baseGoal: Int
    var state: AppState
    let formatter = DateFormatter()
    private var totalGoal: Int
    var healthStore: HealthStore?
    private var dailyTotal: Double = 0.0
    private var steps2: Double = 0.0
    
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
    
    func getSevenDayLog() -> Array<Double>?{
        self.sevenDayLog = Array<Double>()
        
        var date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var i = 0
        
        while i < 7 {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            let predicate = "date == " + "'" + String(formatter.string(from: date)) + "'"
            
            var waterTotal: Double = 0.0
            state.waterReadings!.filter(predicate).forEach{waterReading in
                waterTotal = waterTotal + Double(waterReading.water_level)!
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
    
    func getDailyTotal(day: String) -> Double {
        var dailyTotal: Double = 0.0
        var dayString = ""
        
        if(day == "Yesterday"){
             dayString = String(formatter.string(from: Calendar.current.date(byAdding: .day , value: -1, to: Date())!)) + "'"
        } else {
            dayString = String(formatter.string(from: Date())) + "'"
        }

        state.waterReadings!.filter("date == " + "'" + dayString).forEach{waterReading in
            dailyTotal = dailyTotal + Double(waterReading.water_level)!
        }
        return dailyTotal
    }
    
    func getPercent(day: String) -> Double {
        return getDailyTotal(day: day) / Double(getTotalGoal(day: day))
    }
    
    func getTotalGoal(day: String) -> Int{
        if(state.userData!.weight != "") {
            baseGoal  = Int(state.userData!.weight)! * 2/3
            totalGoal = baseGoal
        } else {
            baseGoal = 80
            totalGoal = 80
        }
        
        let steps = numSteps(day: day)
        
        if(steps >= 5000 && steps < 8000){
            totalGoal += 5
        } else if (steps >= 8000 && steps < 10000){
            totalGoal += 10
        } else if(steps >= 10000){
            totalGoal += 15
        }

        return totalGoal
    }
    
    func numSteps(day: String) -> Int{
        if let healthStore = healthStore{
            healthStore.requestAuthorization { success in
                if(success){
                    healthStore.calculateSteps{statisticsCollection in
                        if let statisticsCollection = statisticsCollection{
                            var startDate = Date()
                            var endDate = Date()
                            
                            if(day == "Yesterday"){
                                startDate = Calendar.current.date(byAdding: .day , value: -1, to: Date())!
                                endDate = Calendar.current.date(byAdding: .day , value: -1, to: Date())!
                            }

                            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics,stop) in
                                self.steps2 = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                            }
                        }
                    }
                }
            }
        }
        
        return Int(self.steps2)
    }
}

