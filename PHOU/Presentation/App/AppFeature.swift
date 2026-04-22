//
//  AppFeature.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import ComposableArchitecture

struct AppFeature {
    enum Tab: Equatable { case gallery, album }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .gallery
        var gallery = GalleryFeature.State()
        var album = AlbumFeature.State()
    }

    @CasePathable
    enum Action {
        case selectTab(Tab)
        case gallery(GalleryFeature.Action)
        case album(AlbumFeature.Action)
    }
}

extension AppFeature: Reducer {
    nonisolated var body: some ReducerOf<Self> {
        Scope(state: \.gallery, action: \.gallery) { GalleryFeature() }
        Scope(state: \.album, action: \.album) { AlbumFeature() }
        Reduce { state, action in
            switch action {
            case let .selectTab(tab):
                state.selectedTab = tab
                return .none
            case .gallery, .album:
                return .none
            }
        }
    }
}
