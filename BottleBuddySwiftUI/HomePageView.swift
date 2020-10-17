//
//  ContentView.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/6/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//

import SwiftUI

struct HomePage: View {
    
    @State var pickerSelectedItem = 0
    //water data points
    @State var dataPoints: [[CGFloat]] = [ [50,100,150,50,100,150,200], [5,10,15,50,100,150,200], [100,200,50,50,100,150,200]]
    var body: some View {

        ZStack {
            Color(#colorLiteral(red: 0.9332545996, green: 0.9333854318, blue: 0.9332134128, alpha: 1)).edgesIgnoringSafeArea(.all)
            VStack{
                Text("Water Intake")
                    .font(.system(size: 34))
                    .fontWeight(.heavy)
                    .foregroundColor(Color(#colorLiteral(red: 0.2939564586, green: 0.3763372302, blue: 0.4621210098, alpha: 1)))
                
                Picker(selection: $pickerSelectedItem,label:Text("")){
                    Text("Ounces Per Day").tag(0)
                    Text("Sips per Day").tag(1)
                    Text("Other").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal,24)
                
                HStack(spacing: 16){
                    BarView(barHeight: dataPoints[pickerSelectedItem][0], day: "Su")
                    BarView(barHeight: dataPoints[pickerSelectedItem][1], day: "M")
                    BarView(barHeight: dataPoints[pickerSelectedItem][2], day: "T")
                    BarView(barHeight: dataPoints[pickerSelectedItem][3], day: "W")
                    BarView(barHeight: dataPoints[pickerSelectedItem][4], day: "Th")
                     BarView(barHeight: dataPoints[pickerSelectedItem][5], day: "F")
                     BarView(barHeight: dataPoints[pickerSelectedItem][6], day: "Sa")
                    
                }
            }
            
            
    }
}

    //Creates an instance of the bar
    struct BarView: View{
        var barHeight: CGFloat = 0;
        var day: String = "D";
        var body: some View{
            VStack{
                 ZStack(alignment: .bottom){
                     Capsule().frame(width:30,height: 200)
                     .foregroundColor(Color(#colorLiteral(red: 0.9452772737, green: 0.8159748912, blue: 0.6461393237, alpha: 1)))
                     Capsule().frame(width:30,height: barHeight)
                     .foregroundColor(Color(#colorLiteral(red: 0.6154652238, green: 0.7253143191, blue: 0.8479378819, alpha: 1)))
            
                 }
                 Text(day).padding(.top,8)
             }
        
    }
    }
struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}
}

