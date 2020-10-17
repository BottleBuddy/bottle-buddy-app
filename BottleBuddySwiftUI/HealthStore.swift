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
    func calculateSteps(completion: @escaping (HKStatisticsCollection?)-> Void){
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        
        let anchorDate = Date.mondayAt12AM()
        
        let daily = DateComponents(day: 1)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end:Date(), options: .strictStartDate)
        
        query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
        
        query?.initialResultsHandler = { query, statisticsCollection, error in
            completion(statisticsCollection)
            
        }
        
        if let healthStore = healthStore, let query = self.query {
            healthStore.execute(query)
        }
        
        
    }
    
    func getSex()->Int{
        var sex = -1
        if try! healthStore?.biologicalSex().biologicalSex == HKBiologicalSex.male  {
            print("You are male")
             sex = 1
        }else if try! healthStore?.biologicalSex().biologicalSex == HKBiologicalSex.female  {
            print("You are female")
             sex = 2
        } else if try! healthStore?.biologicalSex().biologicalSex == HKBiologicalSex.other {
            print("You are not categorized as male or female")
             sex = 3
            
        }
         return sex
    }
    

    
//    func getMostRecentSample(for sampleType: HKSampleType,
//                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
//
//    //1. Use HKQuery to load the most recent samples.
//    let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
//                                                          end: Date(),
//                                                          options: .strictEndDate)
//
//    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
//                                          ascending: false)
//
//    let limit = 1
//
//    let sampleQuery = HKSampleQuery(sampleType: sampleType,
//                                    predicate: mostRecentPredicate,
//                                    limit: limit,
//                                    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
//
//        //2. Always dispatch to the main thread when complete.
//        DispatchQueue.main.async {
//
//          guard let samples = samples,
//                let mostRecentSample = samples.first as? HKQuantitySample else {
//
//                completion(nil, error)
//                return
//          }
//
//          completion(mostRecentSample, nil)
//        }
//      }
//
//    HKHealthStore().execute(sampleQuery)
//    }
//
//
//
//    func getWeight()->Int{
//        guard let heightSampleType = HKSampleType.quantityType(forIdentifier: .height) else {
//          print("Height Sample Type is no longer available in HealthKit")
//          return -1
//        }
//
//        getMostRecentSample(for: heightSampleType) { (sample, error) in
//
//
//            return
//          }
//    }
    
    func requestAuthorization(completion: @escaping (Bool) ->Void){
        
        let stepType = HKQuantityType.quantityType(forIdentifier:  HKQuantityTypeIdentifier.stepCount)!
        let height = HKQuantityType.quantityType(forIdentifier: .height)!
        let sex =  HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
        let mass =  HKSampleType.quantityType(forIdentifier: .bodyMass)!
        
        guard let healthStore = self.healthStore else{return completion(false)}
        
        healthStore.requestAuthorization(toShare: [], read: [stepType,height, sex ,mass]) { (success, error) in
            completion(success)
        }
    }

}


extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}
    




