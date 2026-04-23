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
        var items: [PhotoAsset]
        var currentIndex: Int
        var userAlbums: [AlbumGroup] = []
        var isAlbumPickerPresented = false
        var noticeMessage: String?

        init(items: [PhotoAsset], currentIndex: Int) {
            self.items = items
            self.currentIndex = min(max(currentIndex, 0), max(items.count - 1, 0))
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
                && lhs.currentIndex == rhs.currentIndex
                && lhs.userAlbums == rhs.userAlbums
                && lhs.isAlbumPickerPresented == rhs.isAlbumPickerPresented
                && lhs.noticeMessage == rhs.noticeMessage
                && lhs.items.count == rhs.items.count
                && lhs.currentAssetSnapshot == rhs.currentAssetSnapshot
        }

        private var currentAssetSnapshot: PhotoAsset? {
            guard items.indices.contains(currentIndex) else { return nil }
            return items[currentIndex]
        }
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)

        enum ViewAction: Equatable {
            case dismissTapped
            case currentIndexChanged(Int)
            case favoriteTapped
            case addToAlbumTapped
            case albumSelected(String)
            case albumPickerDismissed
            case deleteConfirmedTapped
            case noticeDismissed
        }

        enum InternalAction: Equatable {
            case userAlbumsLoaded([AlbumGroup])
            case favoriteUpdated(id: String, isFavorite: Bool)
            case assetDeleted(String)
            case notice(String)
        }

        enum DelegateAction: Equatable {
            case assetDeleted(String)
            case favoriteChanged(id: String, isFavorite: Bool)
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.photoLibraryClient) var photoLibraryClient

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

            case .view(.favoriteTapped):
                guard state.items.indices.contains(state.currentIndex) else { return .none }

                let asset = state.items[state.currentIndex]
                let newValue = !asset.isFavorite

                return .run { send in
                    do {
                        try await photoLibraryClient.setFavorite(asset.id, newValue)
                        await send(.internal(.favoriteUpdated(id: asset.id, isFavorite: newValue)))
                    } catch {
                        await send(.internal(.notice(error.localizedDescription)))
                    }
                }

            case .view(.addToAlbumTapped):
                if !state.userAlbums.isEmpty {
                    state.isAlbumPickerPresented = true
                    return .none
                }

                return .run { send in
                    do {
                        let albums = try await photoLibraryClient.fetchAlbums()
                            .filter { $0.albumType == .userAlbum }
                        await send(.internal(.userAlbumsLoaded(albums)))
                    } catch {
                        await send(.internal(.notice(error.localizedDescription)))
                    }
                }

            case let .view(.albumSelected(albumID)):
                guard state.items.indices.contains(state.currentIndex) else { return .none }

                let assetID = state.items[state.currentIndex].id
                state.isAlbumPickerPresented = false

                return .run { send in
                    do {
                        try await photoLibraryClient.addAssetToAlbum(assetID, albumID)
                    } catch {
                        await send(.internal(.notice(error.localizedDescription)))
                    }
                }

            case .view(.albumPickerDismissed):
                state.isAlbumPickerPresented = false
                return .none

            case .view(.deleteConfirmedTapped):
                guard state.items.indices.contains(state.currentIndex) else { return .none }

                let assetID = state.items[state.currentIndex].id
                return .run { send in
                    do {
                        try await photoLibraryClient.deleteAssets([assetID])
                        await send(.internal(.assetDeleted(assetID)))
                    } catch {
                        await send(.internal(.notice(error.localizedDescription)))
                    }
                }

            case .view(.noticeDismissed):
                state.noticeMessage = nil
                return .none

            case let .internal(.userAlbumsLoaded(albums)):
                state.userAlbums = albums
                state.isAlbumPickerPresented = !albums.isEmpty
                if albums.isEmpty {
                    state.noticeMessage = "추가할 수 있는 사용자 앨범이 없어요."
                }
                return .none

            case let .internal(.favoriteUpdated(id, isFavorite)):
                guard let index = state.items.firstIndex(where: { $0.id == id }) else { return .none }
                state.items[index].isFavorite = isFavorite
                return .send(.delegate(.favoriteChanged(id: id, isFavorite: isFavorite)))

            case let .internal(.assetDeleted(id)):
                state.items.removeAll { $0.id == id }

                let deleteEffect: Effect<Action> = .send(.delegate(.assetDeleted(id)))
                guard !state.items.isEmpty else {
                    return .merge(
                        deleteEffect,
                        .run { _ in
                            await dismiss()
                        }
                    )
                }

                state.currentIndex = min(state.currentIndex, state.items.count - 1)
                return deleteEffect

            case let .internal(.notice(message)):
                state.noticeMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
