//
//  AlbumFeature.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

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
