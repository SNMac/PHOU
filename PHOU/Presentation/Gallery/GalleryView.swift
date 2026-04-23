//
//  GalleryView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import SwiftUI
import ComposableArchitecture

struct GalleryView: View {
    @Bindable var store: StoreOf<GalleryFeature>
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
        NavigationStack {
            content
                .navigationTitle("갤러리")
                .onAppear { store.send(.view(.onAppear)) }
                .fullScreenCover(item: $store.scope(state: \.mediaDetail, action: \.mediaDetail)) { store in
                    MediaDetailView(
                        store: store,
                        transitionNamespace: mediaTransitionNamespace
                    )
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.authStatus {
        case .notDetermined:
            loadingView

        case .denied, .restricted:
            deniedView

        case .limited:
            if store.isLoading && store.assets.isEmpty {
                loadingView
            } else {
                limitedMediaGrid
            }

        case .authorized:
            if store.isLoading && store.assets.isEmpty {
                loadingView
            } else {
                mediaGrid
            }
        }
    }

    private var mediaGrid: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(store.assets) { asset in
                        mediaGridCell(
                            asset,
                            cellLength: cellLength(for: proxy.size.width)
                        )
                    }
                }
            }
            .simultaneousGesture(columnResizeGesture)
        }
    }

    private var limitedMediaGrid: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(store.assets) { asset in
                        mediaGridCell(
                            asset,
                            cellLength: cellLength(for: proxy.size.width)
                        )
                    }
                }
                limitedBannerView
            }
            .simultaneousGesture(columnResizeGesture)
        }
    }

    private var limitedBannerView: some View {
        VStack(spacing: 12) {
            Text("접근 가능한 미디어가 제한되어 있어요")
                .font(.headline)
            Text("설정 앱에서 PHOU의 전체 사진 접근을 허용해 주세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("미디어에 접근할 권한이 없어요", systemImage: "photo.slash")
        } description: {
            Text("설정 앱에서 PHOU의 사진 접근을 허용해 주세요.")
        } actions: {
            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func mediaGridCell(_ asset: PhotoAsset, cellLength: CGFloat) -> some View {
        Button {
            store.send(.view(.mediaTapped(asset.id)))
        } label: {
            Color.clear
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    PhotoThumbnailView(
                        id: asset.id,
                        targetSize: CGSize(width: cellLength, height: cellLength)
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
