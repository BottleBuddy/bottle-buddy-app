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
    
    
    @EnvironmentObject var user: User
    
    
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
                                getWaterLog()
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
                    }
                }
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
                                    .trim(from: 0, to: (stat.currentData / stat.goal))
                                    .stroke(stat.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .frame(width: (UIScreen.main.bounds.width - 150) / 2, height: (UIScreen.main.bounds.width - 150) / 2)
                                
                                Text(getPercent(current: stat.currentData, Goal: stat.goal) + " %")
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    .foregroundColor(stat.color)
                                    .rotationEffect(.init(degrees: 90))
                            }
                            .rotationEffect(.init(degrees: -90))
                            
                            Text(getDec(val: stat.currentData) + " " + getType(val: stat.title))
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(15)
                        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 0)
                        
                    }
                }
                Button(action: {
                        
                        self.notifcation.sendNotification(title: "Cleaning Started!", subtitle: nil, body: "Please make sure that the BottleBuddy is secured on the bottle for cleaning.", launchIn: 2)
                        
                        DispatchQueue.global(qos: .background).async {
                            for i in 1...100{
                                print(i)
                            }
                             var date = UInt32(789516)
                            var dateString = convertDate(date: date)
                            print(dateString)
                            var time = UInt32(789516)
                            var timeString = convertTime(time: time)
                            convertDatetoString()
                            print(convertTimetoString())
                            
                        }
                        bluetooth.writeClean()}){
                    Text("Clean My Buddy")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
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
    
    func getPercent(current : CGFloat,Goal : CGFloat)->String{
        
        let per = (current / Goal) * 100
        
        return String(format: "%.1f", per)
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
    
    func getWaterLog(){
        var  i = 0
        
        waterLogData.removeAll()
        state.waterReadings!.forEach{ waterReading in
            i+=1
            var waterLevel = waterReading.water_level
            self.waterLogData.append(WaterLogEntry(id: (i), day: "Day \(i)", water_consumed:getHeight(value: waterLevel)))
            
        }
        
    }
    
    func convertDate(date : UInt32) -> String {
         var dateNum = String(date)
        let dateString = String(Int(dateNum)!, radix: 2)
        
//        var year = dateTimeString.substring(from: String.index(8), to: String.index(16))
       print(dateString)
        var start = dateString.index(dateString.startIndex, offsetBy: 0)
        var end = dateString.index(dateString.endIndex, offsetBy: -16)
        var range = start..<end
        let year = dateString[range]
        print(year)
        let yearNum = Int(year, radix: 2)!
        print(yearNum)


        start = dateString.index(dateString.endIndex, offsetBy: -17)
        end = dateString.index(dateString.endIndex, offsetBy: -9)
        range = start..<end
        let month = dateString[range]
        print(month)
        let monthNum = Int(month, radix: 2)!
        print(monthNum)
        
        
        start = dateString.index(dateString.endIndex, offsetBy: -8)
        end = dateString.index(dateString.endIndex, offsetBy: 0)
        range = start..<end
        let day = dateString[range]
        print(day)
        let dayNum = Int(day, radix: 2)!
        print(dayNum)
        
        
        var finalString = String()
        finalString = String(describing: dayNum)+"-"+String(describing: monthNum)+"-"+String(describing: yearNum)
//
        print("final: ", finalString) // Output: 25
        return finalString
        
    }
    
    func convertTime(time : UInt32) -> String {
         var timeNum = String(time)
        let timeString = String(Int(timeNum)!, radix: 2)

//        var year = dateTimeString.substring(from: String.index(8), to: String.index(16))
       print(timeString)
        var start = timeString.index(timeString.startIndex, offsetBy: 0)
        var end = timeString.index(timeString.endIndex, offsetBy: -16)
        var range = start..<end
        let hour = timeString[range]
        print(hour)
        let hourNum = Int(hour, radix: 2)!
        print(hourNum)


        start = timeString.index(timeString.endIndex, offsetBy: -17)
        end = timeString.index(timeString.endIndex, offsetBy: -9)
        range = start..<end
        let min = timeString[range]
        print(min)
        let minNum = Int(min, radix: 2)!
        print(minNum)


        start = timeString.index(timeString.endIndex, offsetBy: -8)
        end = timeString.index(timeString.endIndex, offsetBy: 0)
        range = start..<end
        let second = timeString[range]
        print(second)
        let secondNum = Int(second, radix: 2)!
        print(secondNum)


        var finalString = String()
        finalString = String(describing: hourNum)+":"+String(describing: minNum)+":"+String(describing: secondNum)
        print("final: ", finalString) // Output: 25
        return finalString
        
    }
    
    
    func convertDatetoString() -> String {
        
        var finalDateString = String()
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
        var date =  formatter.string(from: now)
        print(date)
        
        var dateArr = date.split(separator: "-")
        var day: Int = Int(dateArr[0])!
        let month : Int = Int(dateArr[1])!
        let year : Int = Int(dateArr[2])!
        var dayBinary = String(day, radix: 2)
        var monthBinary = String(month, radix: 2)
        var yearBinary = String(year, radix: 2)
        
        
        for i in Range(0...(8-dayBinary.count-1)){
            dayBinary = "0"+dayBinary
        }
        for i in Range(0...(8-monthBinary.count-1)){
            monthBinary = "0"+monthBinary
        }
        
        for i in Range(0...(16-yearBinary.count-1)){
            yearBinary = "0"+yearBinary
        }
        print("day", dayBinary)
        print("month", monthBinary)
        print("year", yearBinary)
        finalDateString = yearBinary+monthBinary+dayBinary
        print(finalDateString.count)
        
        var dateAnswer = UInt32(finalDateString, radix: 2)
        return finalDateString
        
    }
    
    func convertTimetoString() -> String {
        var finalTimeString = String()
        
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "HH:mm:ss"
        var time = formatter.string(from: now)
        print(time)
        
        var timeArr = time.split(separator: ":")
        var hour: Int = Int(timeArr[0])!
        let min : Int = Int(timeArr[1])!
        let second : Int = Int(timeArr[2])!
        var hourBinary = String(hour, radix: 2)
        var minBinary = String(min, radix: 2)
        var secondBinary = String(second, radix: 2)
        
        
        
        for i in Range(0...(8-hourBinary.count-1)){
            hourBinary = "0"+hourBinary
        }
        for i in Range(0...(8-minBinary.count-1)){
            minBinary = "0"+minBinary
        }
        
        for i in Range(0...(8-secondBinary.count-1)){
            secondBinary = "0"+secondBinary
        }
        print("hour", hourBinary)
        print("min", minBinary)
        print("second", secondBinary)
        finalTimeString = "00000000"+hourBinary+secondBinary+minBinary
        print(finalTimeString.count)
        
        var timeAnswer = UInt32(finalTimeString, radix: 2)
        print(timeAnswer)
        return finalTimeString
        
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


