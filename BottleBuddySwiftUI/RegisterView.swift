//
//  RegisterView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 2/7/21.
//

import SwiftUI
import Firebase

var registeredUser: RegisterView? = nil

var bluetooth = Bluetooth()

struct RegisterView: View {
    //@ObservedObject var bluetooth = Bluetooth()
    @EnvironmentObject var state: AppState
    @State var color = Color.black.opacity(0.7)
    @State var email = ""
    @State var fullName = ""
    @State var pass = ""
    @State var repass = ""
    @State var visible = false
    @State var revisible = false
    //@Binding var show : Bool
    @State var alert = false
    @State var error = ""
    @State var id = ""
    @State var bottleBrandName = 0
    @State var bottleSize = 0
    @State var ageOfUser = ""
    @State var sex = 0
    @State var weight = ""
    
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    
    
    var body: some View {
        NavigationView{
            
            VStack{
                Text("Register to join BottleBuddy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Form{
                    TextField("Email", text: self.$email)
                        .autocapitalization(.none)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 4).stroke(self.email != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 5)
                    
                    TextField("Full Name", text: self.$fullName)
                        .autocapitalization(.none)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 4).stroke(self.fullName != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 5)
                    
                    TextField("Age: " + self.ageOfUser, text: $ageOfUser)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 4).stroke(self.ageOfUser != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 5)
                    
                    TextField("Weight: " + self.weight, text: $weight)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 4).stroke(self.weight != "" ? Color("Color") : self.color,lineWidth: 2))
                        .padding(.top, 5)
                    Section{
                        Picker(selection: $sex, label: Text("Sex")){
                            Text("Male").tag(1)
                            Text("Female").tag(2)
                            Text("Nonbinary").tag(3)
                        }
                        
                        Picker(selection: $bottleBrandName, label: Text("Bottle Brand")){
                            Text("Yeti").tag(1)
                            Text("Hydroflask").tag(2)
                            Text("Thermoflask").tag(3)
                            Text("Other").tag(4)
                        }
                        
                        Picker(selection: $bottleSize, label: Text("Bottle Size")){
                            Text("16 oz").tag(1)
                            Text("18 oz").tag(2)
                            Text("26 oz").tag(3)
                            Text("36 oz").tag(4)
                        }
                    }
                    
                    HStack(spacing: 15){
                        VStack{
                            if self.visible{
                                TextField("Password", text: self.$pass)
                                    .autocapitalization(.none)
                            }
                            else{
                                SecureField("Password", text: self.$pass)
                                    .autocapitalization(.none)
                            }
                        }
                        Button(action: {
                            self.visible.toggle()
                        }) {
                            Image(systemName: self.visible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(self.color)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 4).stroke(self.pass != "" ? Color("Color") : self.color,lineWidth: 2))
                    .padding(.top, 5)
                    
                    
                    HStack(spacing: 15){
                        
                        VStack{
                            
                            if self.revisible{
                                TextField("Re-enter", text: self.$repass)
                                    .autocapitalization(.none)
                            }
                            else{
                                SecureField("Re-enter", text: self.$repass)
                                    .autocapitalization(.none)
                            }
                        }
                        
                        Button(action: {
                            self.revisible.toggle()
                        }) {
                            
                            Image(systemName: self.revisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(self.color)
                        }
                        
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 4).stroke(self.repass != "" ? Color("Color") : self.color,lineWidth: 2))
                    .padding(.top, 5)
                }
                .background(Color(bblightblue!).ignoresSafeArea())
                
                Button(action: {self.register()}){
                    Text("Register")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                }
                .background(Color(UIColor(named: "BB_DarkBlue")!))
                .cornerRadius(10)
                .padding()
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        
        if self.alert{
            ErrorView(alert: self.$alert, error: self.$error)
        }
    }

    
    func register(){
        if self.email != ""{
            if self.pass == self.repass{
                Auth.auth().createUser(withEmail: self.email, password: self.pass) { (res, err) in
                    if err != nil{
                        self.error = err!.localizedDescription
                        self.alert.toggle()
                        
                        return
                    }
                    print("registered successly")
                    registeredUser = self
                    UserDefaults.standard.set(true, forKey: "status")
                    NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
                }
                print("about to scan for bluetooth devices upon registering")
                bluetooth.scanForDevices()
            }
            else{
                self.error = "Password mismatch"
                self.alert.toggle()
            }
        }
        else{
            self.error = "Please fill all the contents properly"
            self.alert.toggle()
        }
    }
    
    
    struct RegisterView_Previews: PreviewProvider {
        static var previews: some View {
            RegisterView()
        }
    }
}
