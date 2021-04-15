//
//  ContentView.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/6/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//
import SwiftUI
import UserNotifications
import RealmSwift


struct HomePage: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var bluetooth: Bluetooth
    var columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    @State var selected = 0
    var colors = [Color(.white)]
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    //var waterLogData: [WaterLogEntry]
    @State var waterLogData = [WaterLogEntry]()
    @State var alert = false
    let notifContent = UNMutableNotificationContent()
    let timer = Timer.publish(every: 0.5, on : .main, in: .common).autoconnect()
    @State var name: String = ""
    @State var stats: Statistics? = nil
    
    @ObservedObject var notifcation = NotificationManager()
    
    
    var body: some View {
        
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack{
                
                HStack{
                    //TODO: update with dynamic user's name
                    
                    Text("Welcome " + self.name + "!")
                        
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {}) {
                        
                        Image("menu")
                            .renderingMode(.template)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .onReceive(timer, perform: { _ in
                    if(state.userData != nil){
                        if(state.userData?.name != nil){
                            self.name = state.userData!.name
                        } else {
                            self.name = state.email
                        }
                    }
                })

                
                // Bar Chart...
                
                VStack(alignment: .leading, spacing: 25) {
                    Text("Daily Water Consumption")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .onReceive(timer){_ in
                            if(state.waterReadings != nil){
                                if(stats == nil){
                                    stats = Statistics(state: state)
                                }
                                getWaterLog(stats: self.stats!)
                            }
                        }

                    
                    
                    HStack(spacing: 15){
                        
                        ForEach(self.waterLogData){waterLogEntry in
                            
                            // Bars...
                            
                            VStack{
                                VStack{
                                    Spacer(minLength: 0)
                                    
                                    if selected == waterLogEntry.id{
                                        
                                        Text(getDec(val: waterLogEntry.water_consumed))
                                            .foregroundColor(Color(bbyellow!))
                                            .padding(.bottom,5)
                                    }
                                    RoundedShape()
                                        .fill(LinearGradient(gradient: .init(colors: selected == waterLogEntry.id ? colors : [Color.white.opacity(0.06)]), startPoint: .top, endPoint: .bottom))
                                        // max height = 200
                                        .frame(height: waterLogEntry.water_consumed)
                                }
                                .frame(height: 220)
                                .onTapGesture {
                                    
                                    withAnimation(.easeOut){
                                        
                                        selected = waterLogEntry.id
                                    }
                                }
                                Text(waterLogEntry.day)
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x:0, y:5)

                    }
                }
                .shadow(color: Color.black.opacity(0.2), radius: 5, x:0, y:5)
                .padding()
                .background(Color(bbdarkblue!).ignoresSafeArea())
                .cornerRadius(10)
                .padding()
                
                
                HStack{
                    
                    Text("Statistics")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 0)
                }
                .padding()
                
                // stats Grid....
                
                LazyVGrid(columns: columns,spacing: 30){
                    
                    ForEach(stats_Data){stat in
                        VStack(spacing: 32){
                            HStack{
                                Text(stat.title)
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer(minLength: 0)
                            }
                            
                            // Ring...
                            
                            ZStack{
                                Circle()
                                    .trim(from: 0, to: 1)
                                    .stroke(stat.color.opacity(0.05), lineWidth: 10)
                                    .frame(width: (UIScreen.main.bounds.width - 150) / 2, height: (UIScreen.main.bounds.width - 150) / 2)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(self.stats?.getPercent() ?? 0))
                                    .stroke(stat.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .frame(width: (UIScreen.main.bounds.width - 150) / 2, height: (UIScreen.main.bounds.width - 150) / 2)
                                
                                Text(getPercent(val: self.stats?.getPercent() ?? 0) + "%")
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    .foregroundColor(stat.color)
                                    .rotationEffect(.init(degrees: 90))
                            }
                            .rotationEffect(.init(degrees: -90))
                            
                            Text(String(self.stats?.getDailyTotal() ?? 0) + " " + getType(val: stat.title))
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
                        
                    }
                    .padding()
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x:0, y:5)
                }
                Button(action: {
                    
                    self.notifcation.sendNotification(title: "Cleaning Started!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 2)
                    
                bluetooth.writeData()}){
                    Text("Clean My Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                .padding()
//                Button(action: {
//                    //TODO: initiate cleaning protocol on button click
//                    self.notifcation.sendNotification(title: "Cleaning Started!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 5)
//
//                }){
//                    Text("Start Cleaning")
//                        .foregroundColor(.white)
//                        .padding(.vertical)
//                        .frame(width: UIScreen.main.bounds.width - 50)
//                }
//                .background(Color(UIColor(named: "BB_DarkBlue")!))
//                .cornerRadius(10)
//                .padding()
            }
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        
    }
    
    // calculating Type...
    
    func getType(val: String)->String{
        
        switch val {
        case "Water Intake Today": return "L"
        case "Days Until Cleaning": return "Days"
        default: return "X"
        }
    }
    
    // converting Number to decimal...
    
    func getDec(val: CGFloat)->String{
        
        let format = NumberFormatter()
        format.numberStyle = .decimal
        
        return format.string(from: NSNumber.init(value: Float(val)))!
    }
    
    // calculating percent...
    
    func getPercent(val: Double)->String{
        return String(format: "%.1f", val*100)
    }
    
    // calculating Hrs For Height...
    
    func getHeight(value : String)->CGFloat{
        
        // the value in minutes....
        // 24 hrs in min = 1440
        guard let n = NumberFormatter().number(from: value) else {return CGFloat(-1)}
        return CGFloat(n)
        //        let hrs = CGFloat(n / 1440) * 200
        //
        //        return hrs
    }
    
    // getting hrs...
    
    func getHrs(value: CGFloat)->String{
        
        let hrs = value / 60
        
        return String(format: "%.1f", hrs)
    }
    
    func getWaterLog(stats: Statistics){
        var  i = 0
        
        waterLogData.removeAll()
        for volume in stats.getSevenDayLog()! {
            self.waterLogData.append(WaterLogEntry(id: (i), day: "Day \(i)",
                                                   water_consumed:getHeight(value: String(volume))))
            i = i + 1
        }
    }
    
    
    
    struct RoundedShape : Shape {
        
        func path(in rect: CGRect) -> Path {
            
            
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize(width: 5, height: 5))
            
            return Path(path.cgPath)
        }
    }
    
    // sample Data...
    
    struct WaterLogEntry : Identifiable {
        
        var id : Int
        var day : String
        var water_consumed : CGFloat
    }
    
    
    struct Stats : Identifiable {
        
        var id : Int
        var title : String
        var currentData : CGFloat
        var goal : CGFloat
        var color : Color
    }
    
    //TODO: make currentData variable w data from database
    var stats_Data = [
        Stats(id: 1, title: "Water Intake Today", currentData: 3.5, goal: 5, color: Color(.yellow)),
        Stats(id: 3, title: "Days Until Cleaning", currentData: 6.2, goal: 10, color: Color(.yellow))
    ]
    
    struct HomePage_Previews: PreviewProvider {
        static var previews: some View {
            HomePage()
            
        }
    }


}
