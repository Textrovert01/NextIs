//
//  SettingsView.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PlayfulBackground()
                VStack(spacing: 16) {
                    Text("Settings").font(.title).bold()
                    Text("Configure the app here.").foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}