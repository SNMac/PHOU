//
//  MediaDetailFeature.swift
//  PHOU
//
//  Created by Codex on 4/23/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct MediaDetailFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        let id = UUID()
        let items: [PhotoAsset]
        var currentIndex: Int

        init(items: [PhotoAsset], currentIndex: Int) {
            self.items = items
            self.currentIndex = min(max(currentIndex, 0), max(items.count - 1, 0))
        }
    }

    enum Action {
        case view(ViewAction)

        enum ViewAction: Equatable {
            case dismissTapped
            case currentIndexChanged(Int)
        }
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.dismissTapped):
                return .run { _ in
                    await dismiss()
                }

            case let .view(.currentIndexChanged(index)):
                guard state.items.indices.contains(index) else { return .none }
                state.currentIndex = index
                return .none
            }
        }
    }
}
