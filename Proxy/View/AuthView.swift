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
    @State private var confirmPassword = ""

    @State private var showPassword = false
    @State private var showConfirmPassword = false

    // Unique IDs to force SwiftUI to recreate the field (fixes SecureField typing bug)
    @State private var passwordFieldID = UUID()
    @State private var confirmFieldID = UUID()

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    let brandRedOrange = Color(red: 1.0, green: 0.3, blue: 0.1)

    var body: some View {
        ZStack {
            LinearGradient(colors: [brandRedOrange, brandOrange], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {

                    Image("dogIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                        .padding(.top, 40)

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

                        // Password field — use .id() to force recreation on toggle
                        HStack {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .id(passwordFieldID)
                            } else {
                                SecureField("Password", text: $password)
                                    .id(passwordFieldID)
                            }
                            Button {
                                passwordFieldID = UUID()
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)

                        if !isLogin {
                            // Confirm password field
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                        .id(confirmFieldID)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .id(confirmFieldID)
                                }
                                Button {
                                    confirmFieldID = UUID()
                                    showConfirmPassword.toggle()
                                } label: {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 30)

                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Button(action: {
                            Task {
                                if isLogin {
                                    await viewModel.signIn(identifier: email, password: password)
                                } else {
                                    if password != confirmPassword {
                                        viewModel.errorMessage = "Passwords do not match."
                                        return
                                    }
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
                        withAnimation {
                            isLogin.toggle()
                            showPassword = false
                            showConfirmPassword = false
                            confirmPassword = ""
                            passwordFieldID = UUID()
                            confirmFieldID = UUID()
                        }
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

                    Spacer(minLength: 30)
                }
            }
        }
    }
}
