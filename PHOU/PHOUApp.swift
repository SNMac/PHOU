//
//  PHOUApp.swift
//  PHOU
//
//  Created by 서동환 on 3/3/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct PHOUApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
