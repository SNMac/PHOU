//
//  AppView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            GalleryView(store: store.scope(state: \.gallery, action: \.gallery))
                .tabItem { Label("갤러리", systemImage: "photo.on.rectangle") }
                .tag(AppFeature.Tab.gallery)

            AlbumView(store: store.scope(state: \.album, action: \.album))
                .tabItem { Label("앨범", systemImage: "rectangle.stack") }
                .tag(AppFeature.Tab.album)
        }
    }
}
