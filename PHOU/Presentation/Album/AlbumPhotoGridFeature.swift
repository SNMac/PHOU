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
        var photos: [PhotoAsset] = []
        var isLoading = false
        var errorMessage: String?
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)

        enum ViewAction {
            case onAppear
            case retryTapped
        }

        enum InternalAction {
            case photosResponse(Result<[PhotoAsset], Error>)
        }
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                guard !state.isLoading else { return .none }
                return fetchPhotos(state: &state)

            case .view(.retryTapped):
                return fetchPhotos(state: &state)

            case let .internal(.photosResponse(.success(photos))):
                state.photos = photos
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case let .internal(.photosResponse(.failure(error))):
                state.photos = []
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }

    private func fetchPhotos(state: inout State) -> Effect<Action> {
        let albumId = state.albumId
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            await send(.internal(.photosResponse(
                Result { try await photoLibraryClient.fetchAssetsInAlbum(albumId) }
            )))
        }
    }
}
