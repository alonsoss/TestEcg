//
//  ContentView.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 13.08.20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Home()
    }
}

struct Home: View {
    var body: some View {
        PullToRefreshView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
