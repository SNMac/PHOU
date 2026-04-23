//
//  AlbumPhotoGridView.swift
//  PHOU
//
//  Created by 서동환 on 4/23/26.
//

import SwiftUI
import ComposableArchitecture

struct AlbumPhotoGridView: View {
    @Bindable var store: StoreOf<AlbumPhotoGridFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        content
            .navigationTitle(store.albumTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.view(.onAppear)) }
            .fullScreenCover(item: $store.scope(state: \.mediaDetail, action: \.mediaDetail)) { store in
                MediaDetailView(store: store)
            }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.assets.isEmpty {
            loadingView
        } else if let errorMessage = store.errorMessage {
            errorView(message: errorMessage)
        } else {
            photoGrid
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("미디어를 불러오지 못했어요", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("다시 시도") {
                store.send(.view(.retryTapped))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(store.assets) { asset in
                    Button {
                        store.send(.view(.mediaTapped(asset.id)))
                    } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                PhotoThumbnailView(id: asset.id)
                                    .overlay(alignment: .bottomTrailing) {
                                        if asset.mediaType == .video {
                                            Image(systemName: "video.fill")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.white)
                                                .padding(6)
                                                .background(.black.opacity(0.6))
                                                .clipShape(Circle())
                                                .padding(6)
                                        }
                                    }
                            }
                            .clipped()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
