//
//  ProxyApp.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct ProxyApp: App {
   
    @StateObject var viewModel = AppViewModel()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {

            if viewModel.userSession != nil {
                ContentView()
                    .environmentObject(viewModel)
            } else {
                AuthView()
                    .environmentObject(viewModel)
            }
        }
    }
}
