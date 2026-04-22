//
//  GalleryFeature.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import ComposableArchitecture

@Reducer
struct GalleryFeature {
    @ObservableState
    struct State: Equatable {
        var authStatus: PhotoAuthStatus = .notDetermined
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
            case authResponse(PhotoAuthStatus)
            case photosResponse(Result<[PhotoAsset], Error>)
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

            case let .internal(.authResponse(status)):
                state.authStatus = status
                switch status {
                case .authorized, .limited:
                    return .run { send in
                        await send(.internal(.photosResponse(
                            Result { try await photoLibraryClient.fetchPhotos() }
                        )))
                    }
                default:
                    state.isLoading = false
                    return .none
                }

            case let .internal(.photosResponse(.success(photos))):
                state.photos = photos
                state.isLoading = false
                return .none

            case let .internal(.photosResponse(.failure(error))):
                state.errorMessage = error.localizedDescription
                state.isLoading = false
                return .none
            }
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
