//
//  GalleryFeature.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct GalleryFeature {
    @ObservableState
    struct State: Equatable {
        var authStatus: PhotoAuthStatus = .notDetermined
        var assets: [PhotoAsset] = []
        var isLoading = false
        var errorMessage: String?
        @Presents var mediaDetail: MediaDetailFeature.State?
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)
        case mediaDetail(PresentationAction<MediaDetailFeature.Action>)

        enum ViewAction {
            case onAppear
            case retryTapped
            case mediaTapped(String)
        }

        enum InternalAction {
            case authResponse(PhotoAuthStatus)
            case mediaResponse(Result<[PhotoAsset], Error>)
        }
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isLoading else { return .none }
                return requestAuth(state: &state)

            case .view(.retryTapped):
                return requestAuth(state: &state)

            case let .view(.mediaTapped(id)):
                guard
                    let currentIndex = state.assets.firstIndex(where: { $0.id == id })
                else { return .none }

                state.mediaDetail = MediaDetailFeature.State(
                    items: state.assets,
                    currentIndex: currentIndex
                )
                return .none

            case let .internal(.authResponse(status)):
                state.authStatus = status
                switch status {
                case .authorized, .limited:
                    return .run { send in
                        await send(.internal(.mediaResponse(
                            Result { try await photoLibraryClient.fetchMedia() }
                        )))
                    }
                default:
                    state.isLoading = false
                    return .none
                }

            case let .internal(.mediaResponse(.success(assets))):
                state.assets = assets
                state.isLoading = false
                return .none

            case let .internal(.mediaResponse(.failure(error))):
                state.errorMessage = error.localizedDescription
                state.isLoading = false
                return .none

            case .mediaDetail:
                return .none
            }
        }
        .ifLet(\.$mediaDetail, action: \.mediaDetail) {
            MediaDetailFeature()
        }
    }

    private func requestAuth(state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            let status = await photoLibraryClient.requestAuthorization()
            await send(.internal(.authResponse(status)))
        }
    }
}
