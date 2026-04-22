import ComposableArchitecture

@Reducer
struct AlbumFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action {}

    var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
