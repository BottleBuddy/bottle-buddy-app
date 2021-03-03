//
//  RegisterView.swift
//  BottleBuddySwiftUI
//
//  Created by Flannery Thompson on 2/7/21.
//

import SwiftUI
import Firebase

var displayName = ""

struct RegisterView: View {
    
    @State var color = Color.black.opacity(0.7)
    @State var email = ""
    @State var firstName = ""
    @State var lastName = ""
    @State var pass = ""
    @State var repass = ""
    @State var visible = false
    @State var revisible = false
    //@Binding var show : Bool
    @State var alert = false
    @State var error = ""
    @State var id = ""
    
    let bbdarkblue = UIColor(named: "BB_DarkBlue")
    let bblightblue = UIColor(named: "BB_LightBlue")
    let bbyellow = UIColor(named: "BB_Yellow")
    
    var body: some View {
        ZStack{
            ZStack(alignment: .top) {
                GeometryReader{_ in
                    VStack{
                        Image("logo")
                        Text("Register to join BottleBuddy")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 5)
                        
                        TextField("Email", text: self.$email)
                            .autocapitalization(.none)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 4).stroke(self.email != "" ? Color("Color") : self.color,lineWidth: 2))
                            .padding(.top, 5)
                        
                        TextField("First Name", text: self.$firstName)
                            .autocapitalization(.none)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 4).stroke(self.firstName != "" ? Color("Color") : self.color,lineWidth: 2))
                            .padding(.top, 5)
                        
                        TextField("Last Name", text: self.$lastName)
                            .autocapitalization(.none)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 4).stroke(self.lastName != "" ? Color("Color") : self.color,lineWidth: 2))
                            .padding(.top, 5)
                        
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
                        
                        Button(action: {
                            
                            self.register()
                        }) {
                            
                            Text("Register")
                                .foregroundColor(.white)
                                .padding(.vertical)
                                .frame(width: UIScreen.main.bounds.width - 50)
                        }
                        .background(Color(.black))
                        .cornerRadius(10)
                        .padding(.top, 5)
                    }
                    .padding(.horizontal, 25.0)
                }
                
            }
            .background(Color(bblightblue!).ignoresSafeArea())
            .frame(maxHeight: .infinity)
            
            if self.alert{
                ErrorView(alert: self.$alert, error: self.$error)
            }
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
                    print("success")
                    displayName = self.firstName+" "+self.lastName
                    print(displayName)
                    UserDefaults.standard.set(true, forKey: "status")
                    NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
                }
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
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
