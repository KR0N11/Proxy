import SwiftUI

struct AuthView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "location.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)

                Text("Proxy")
                    .font(.largeTitle.bold())

                VStack(spacing: 14) {
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)

                Button {
                    if isSignUp {
                        firebaseService.signUp(name: name, email: email, password: password)
                    } else {
                        firebaseService.signIn(email: email, password: password)
                    }
                } label: {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .disabled(email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))

                Button {
                    isSignUp.toggle()
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
