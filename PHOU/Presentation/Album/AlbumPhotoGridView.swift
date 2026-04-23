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
    @Namespace private var mediaTransitionNamespace
    @State private var columnCount = 3
    @State private var pinchStartColumnCount: Int?

    private let gridSpacing: CGFloat = 2
    private let minColumnCount = 2
    private let maxColumnCount = 6

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnCount)
    }

    var body: some View {
        content
            .navigationTitle(store.albumTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.view(.onAppear)) }
            .fullScreenCover(item: $store.scope(state: \.mediaDetail, action: \.mediaDetail)) { store in
                MediaDetailView(
                    store: store,
                    transitionNamespace: mediaTransitionNamespace
                )
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
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(store.assets) { asset in
                        Button {
                            store.send(.view(.mediaTapped(asset.id)))
                        } label: {
                            Color.clear
                                .aspectRatio(1, contentMode: .fill)
                                .overlay {
                                    PhotoThumbnailView(
                                        id: asset.id,
                                        targetSize: CGSize(
                                            width: cellLength(for: proxy.size.width),
                                            height: cellLength(for: proxy.size.width)
                                        )
                                    )
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
                                .matchedTransitionSource(id: asset.id, in: mediaTransitionNamespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .simultaneousGesture(columnResizeGesture)
        }
    }

    private var columnResizeGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if pinchStartColumnCount == nil {
                    pinchStartColumnCount = columnCount
                }

                guard let pinchStartColumnCount else { return }
                let proposed = Int((CGFloat(pinchStartColumnCount) / value.magnification).rounded())
                columnCount = clampedColumnCount(proposed)
            }
            .onEnded { _ in
                pinchStartColumnCount = nil
            }
    }

    private func cellLength(for availableWidth: CGFloat) -> CGFloat {
        let totalSpacing = gridSpacing * CGFloat(max(columnCount - 1, 0))
        return floor((availableWidth - totalSpacing) / CGFloat(columnCount))
    }

    private func clampedColumnCount(_ value: Int) -> Int {
        min(max(value, minColumnCount), maxColumnCount)
    }
}
