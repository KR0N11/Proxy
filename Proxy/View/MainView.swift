//
//  MainView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//



import SwiftUI

struct MainView: View {

    @State private var selection = 1
    
    var body: some View {
        TabView(selection: $selection) {

            ChatListView()
                .tag(0)

            MapView()
                .tag(1)

            ProfileView()
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}
