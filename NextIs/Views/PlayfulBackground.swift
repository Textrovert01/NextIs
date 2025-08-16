//
//  PlayfulBackground.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import SwiftUI

struct PlayfulBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.98, green: 0.86, blue: 0.99), location: 0.0),
                .init(color: Color(red: 0.86, green: 0.95, blue: 1.00), location: 0.25),
                .init(color: Color(red: 1.00, green: 0.95, blue: 0.80), location: 0.50),
                .init(color: Color(red: 0.87, green: 1.00, blue: 0.90), location: 0.75),
                .init(color: Color(red: 0.95, green: 0.87, blue: 1.00), location: 1.00)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}