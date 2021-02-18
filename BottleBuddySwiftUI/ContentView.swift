//
//  ContentView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 10/10/20.
//

import SwiftUI
import Firebase

struct ContentView: View {
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    @EnvironmentObject var user: User
    
    var body: some View {
        LoginSignin().environmentObject(user)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct LoginSignin : View {
    
    @State var show = false
    @State var status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
    @EnvironmentObject var user: User
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    
    init() {
        UIScrollView.appearance().backgroundColor = (bblightblue!)
    }
    
    var body: some View{
        
        NavigationView{
            
            VStack{
                if self.status{
                    Dashboard().environmentObject(user)
                }
                else{
                    ZStack{
                        Login(show: self.$show)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name("status"), object: nil, queue: .main) { (_) in
                    self.status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
                }
            }
        }
    }
}

struct Login : View {
    
    @State var color = Color.black.opacity(0.7)
    @State var email = ""
    @State var pass = ""
    @State var visible = false
    @Binding var show : Bool
    @State var alert = false
    @State var error = ""
    
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    
    
    var body: some View{
        
        ZStack(alignment: .top){
            VStack(alignment: .center){
                Image("logo")
                    .padding(.horizontal)
                
                Text("Log in to your account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(self.color)
                    .padding(.top, 35)
                
                TextField("Email", text: self.$email)
                    .autocapitalization(.none)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 4).stroke(self.email != "" ? Color("Color") : self.color,lineWidth: 2))
                    .padding(.top, 25)
                
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
                .padding(.top, 25)
                
                HStack{
                    Spacer()
                    Button(action: {
                        self.reset()
                        
                    }) {
                        Text("Forgot password?")
                            .fontWeight(.bold)
                            .foregroundColor(Color("Color"))
                    }
                }
                .padding(.top, 20)
                Button(action: {
                    self.verify()
                }) {
                    Text("Log in")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                }
                .background(Color(bbdarkblue!))
                .cornerRadius(10)
                .padding(.top, 25)
                
                NavigationLink(destination: RegisterView()){
                    Text("Register")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 50)
                        .background(Color(UIColor(named: "BB_DarkBlue")!))
                        .cornerRadius(10)
                }
                
            }
            .padding(.horizontal, 25)
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxHeight: .infinity)
            
            if self.alert{
                ErrorView(alert: self.$alert, error: self.$error)
            }
        }
        .background(Color(bblightblue!).ignoresSafeArea())
        .frame(maxHeight: .infinity)
    }
    
    func verify(){
        if self.email != "" && self.pass != ""{
            Auth.auth().signIn(withEmail: self.email, password: self.pass) { (res, err) in
                if err != nil{
                    self.error = err!.localizedDescription
                    self.alert.toggle()
                    return
                }
                
                print("success")
                UserDefaults.standard.set(true, forKey: "status")
                NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
            }
        }
        else{
            
            self.error = "Please fill all the contents properly"
            self.alert.toggle()
        }
    }
    
    func reset(){
        
        if self.email != ""{
            Auth.auth().sendPasswordReset(withEmail: self.email) { (err) in
                if err != nil{
                    self.error = err!.localizedDescription
                    self.alert.toggle()
                    return
                }
                self.error = "RESET"
                self.alert.toggle()
            }
        }
        else{
            
            self.error = "Email ID is empty"
            self.alert.toggle()
        }
    }
}


struct ErrorView : View {
    
    @State var color = Color.black.opacity(0.7)
    @Binding var alert : Bool
    @Binding var error : String
    
    var body: some View{
        
        GeometryReader{_ in
            VStack{
                HStack{
                    Text(self.error == "RESET" ? "Message" : "Error")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(self.color)
                    
                    Spacer()
                }
                .padding(.horizontal, 25)
                
                Text(self.error == "RESET" ? "Password reset link has been sent successfully" : self.error)
                    .foregroundColor(self.color)
                    .padding(.top)
                    .padding(.horizontal, 25)
                
                Button(action: {
                    self.alert.toggle()
                }) {
                    
                    Text(self.error == "RESET" ? "Ok" : "Cancel")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 120)
                }
                .background(Color("Color"))
                .cornerRadius(10)
                .padding(.top, 25)
                
            }
            .padding(.vertical, 25)
            .frame(width: UIScreen.main.bounds.width - 70)
            .background(Color.white)
            .cornerRadius(15)
        }
        .background(Color.gray.opacity(0.35).edgesIgnoringSafeArea(.all))
    }
}
