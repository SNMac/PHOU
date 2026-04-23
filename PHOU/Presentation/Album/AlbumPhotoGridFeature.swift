//
//  AlbumPhotoGridFeature.swift
//  PHOU
//
//  Created by 서동환 on 4/23/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AlbumPhotoGridFeature {
    @ObservableState
    struct State: Equatable {
        var albumId: String
        var albumTitle: String
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
            case assetsResponse(Result<[PhotoAsset], Error>)
        }
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isLoading else { return .none }
                return fetchAssets(state: &state)

            case .view(.retryTapped):
                return fetchAssets(state: &state)

            case let .view(.mediaTapped(id)):
                guard
                    let currentIndex = state.assets.firstIndex(where: { $0.id == id })
                else { return .none }

                state.mediaDetail = MediaDetailFeature.State(
                    items: state.assets,
                    currentIndex: currentIndex
                )
                return .none

            case let .internal(.assetsResponse(.success(assets))):
                state.assets = assets
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case let .internal(.assetsResponse(.failure(error))):
                state.assets = []
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .mediaDetail:
                return .none
            }
        }
        .ifLet(\.$mediaDetail, action: \.mediaDetail) {
            MediaDetailFeature()
        }
    }

    private func fetchAssets(state: inout State) -> Effect<Action> {
        let albumId = state.albumId
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            await send(.internal(.assetsResponse(
                Result { try await photoLibraryClient.fetchAssetsInAlbum(albumId) }
            )))
        }
    }
}
