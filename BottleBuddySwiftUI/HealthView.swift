//
//  HealthView.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/13/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//

import SwiftUI
import HealthKit

struct HealthView: View {
    
    private var healthStore:  HealthStore?
    @State private var steps: [Step] = [Step]()
    @State private var newPeople : [User] = [User]()
    
    
    init(){
        healthStore = HealthStore()
    }
    
    private func updateUIFromStatistics( statisticsCollection: HKStatisticsCollection){
        steps.removeAll()
        let startDate = Calendar.current.date(byAdding: .day , value: -7, to: Date())!
        let endDate = Date()
        
        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics,stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            
            let step = Step(count: Int(count ?? 0), date: statistics.startDate)
            steps.append(step)
            
        }
    }
    
    
    var body: some View {
        
        NavigationView{
            
            List(steps, id: \.id) { step in
                VStack(alignment: .leading){
                    Text("\(step.count)")
                    if #available(iOS 14.0, *) {
                        Text(step.date, style: .date)
                            .opacity(0.5)
                    } else {
                        // Fallback on earlier versions
                        Text("\(step.count)")
                        
                    }
                }
            }
            .navigationBarTitle("Steps")
        }
        
        .onAppear{
            if let healthStore = healthStore{
                healthStore.requestAuthorization { success in
                    if(success){
                        print(success)
                        
                        healthStore.calculateSteps{statisticsCollection in
                            if let statisticsCollection = statisticsCollection{
                                print(statisticsCollection)
                                updateUIFromStatistics(statisticsCollection: statisticsCollection)
                            }
                        }
                        
                    }
                }
            }
        }
    }
}



struct HealthView_Previews: PreviewProvider {
    static var previews: some View {
        HealthView()
    }
}





