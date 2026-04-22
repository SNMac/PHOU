import ComposableArchitecture

@Reducer
struct AppFeature {
    enum Tab: Equatable { case gallery, album }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .gallery
        var gallery = GalleryFeature.State()
        var album = AlbumFeature.State()
    }

    enum Action {
        case selectTab(Tab)
        case gallery(GalleryFeature.Action)
        case album(AlbumFeature.Action)
    }

    var body: some ReducerOf<Self> {
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
