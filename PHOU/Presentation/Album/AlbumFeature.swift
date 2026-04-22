//
//  AlbumFeature.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import ComposableArchitecture

struct AlbumFeature {
    @ObservableState
    struct State: Equatable {}

    @CasePathable
    enum Action {
        case onAppear
    }
}

extension AlbumFeature: Reducer {
    nonisolated func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .none
        }
    }
}
