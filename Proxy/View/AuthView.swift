//
//  AuthView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    let brandRedOrange = Color(red: 1.0, green: 0.3, blue: 0.1)
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [brandRedOrange, brandOrange], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                Image("dogIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                
                Text("PROXY")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                VStack(spacing: 15) {
                    if !isLogin {
                        TextField("Username", text: $username)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                    }
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Button(action: {
                        Task {
                            if isLogin {
                                await viewModel.signIn(email: email, password: password)
                            } else {
                                await viewModel.signUp(email: email, password: password, username: username)
                            }
                        }
                    }) {
                        Text(isLogin ? "LOG IN" : "SIGN UP")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(brandRedOrange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(25)
                            .padding(.horizontal, 30)
                            .shadow(radius: 3)
                    }
                }
                
                Button(action: {
                    withAnimation { isLogin.toggle() }
                }) {
                    Text(isLogin ? "New here? Create Account" : "Have an account? Log In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.5))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
    }
}
