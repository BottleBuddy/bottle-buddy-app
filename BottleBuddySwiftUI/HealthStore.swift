//
//  HealthStore.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/13/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//

import Foundation
import HealthKit

class HealthStore{
    
    var healthStore: HKHealthStore?
    var query: HKStatisticsCollectionQuery?


    init(){
        if HKHealthStore.isHealthDataAvailable(){
            healthStore = HKHealthStore()
        }
    }
    
    func calculateSteps() -> Double {
        var steps: Double = 20.0
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let current = Date()
        let start = Calendar.current.startOfDay(for: current)
        var daily = DateComponents()
        daily.day = 1
        
        self.query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: nil, options: [.cumulativeSum], anchorDate: start, intervalComponents: daily)
        
        self.query?.initialResultsHandler = { _, result, error in
                result!.enumerateStatistics(from: start, to: current) { statistics, _ in

                if let sum = statistics.sumQuantity() {
                    steps = sum.doubleValue(for: HKUnit.count())
                }
            }
        }
        
        self.query?.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in

            if let sum = statistics?.sumQuantity() {
                steps = sum.doubleValue(for: HKUnit.count())
            }
        }

        self.healthStore?.execute(query!)
        
        return steps
        
    }
    
    func requestAuthorization(completion: @escaping (Bool) ->Void){
        
        let stepType: Set = [HKQuantityType.quantityType(forIdentifier:  HKQuantityTypeIdentifier.stepCount)!]
        
        guard let healthStore = self.healthStore else{return completion(false)}
        
        healthStore.requestAuthorization(toShare: nil, read: stepType) { (success, error) in
            completion(success)
        }
    }

}

    




