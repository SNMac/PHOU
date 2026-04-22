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
    struct State: Equatable {
        var authStatus: PhotoAuthStatus = .notDetermined
        var albums: [AlbumGroup] = []
        var isLoading = false
        var errorMessage: String?
        @PresentationState var albumPhotoGrid: AlbumPhotoGridFeature.State?
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)
        case albumPhotoGrid(PresentationAction<AlbumPhotoGridFeature.Action>)

        enum ViewAction {
            case onAppear
            case retryTapped
            case albumTapped(AlbumGroup)
        }

        enum InternalAction {
            case authResponse(PhotoAuthStatus)
            case albumsResponse(Result<[AlbumGroup], Error>)
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

            case .view(.albumTapped(let album)):
                state.albumPhotoGrid = AlbumPhotoGridFeature.State(albumId: album.id, albumTitle: album.title)
                return .none

            case let .internal(.authResponse(status)):
                state.authStatus = status
                switch status {
                case .authorized, .limited:
                    return .run { send in
                        await send(.internal(.albumsResponse(
                            Result { try await photoLibraryClient.fetchAlbums() }
                        )))
                    }
                default:
                    state.isLoading = false
                    return .none
                }

            case let .internal(.albumsResponse(.success(albums))):
                state.albums = albums
                state.isLoading = false
                return .none

            case let .internal(.albumsResponse(.failure(error))):
                state.errorMessage = error.localizedDescription
                state.isLoading = false
                return .none

            case .albumPhotoGrid:
                return .none
            }
        }
        .ifLet(\.$albumPhotoGrid, action: \.albumPhotoGrid) {
            AlbumPhotoGridFeature()
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
