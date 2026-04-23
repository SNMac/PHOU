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

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("갤러리")
                .onAppear { store.send(.view(.onAppear)) }
                .fullScreenCover(item: $store.scope(state: \.mediaDetail, action: \.mediaDetail)) { store in
                    MediaDetailView(store: store)
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(store.assets) { asset in
                    mediaGridCell(asset)
                }
            }
        }
    }

    private var limitedMediaGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(store.assets) { asset in
                    mediaGridCell(asset)
                }
            }
            limitedBannerView
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

    private func mediaGridCell(_ asset: PhotoAsset) -> some View {
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
