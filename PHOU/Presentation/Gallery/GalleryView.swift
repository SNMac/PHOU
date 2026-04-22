//
//  GalleryView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import SwiftUI
import ComposableArchitecture

struct GalleryView: View {
    let store: StoreOf<GalleryFeature>

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
            if store.isLoading && store.photos.isEmpty {
                loadingView
            } else {
                limitedPhotoGrid
            }

        case .authorized:
            if store.isLoading && store.photos.isEmpty {
                loadingView
            } else {
                photoGrid
            }
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(store.photos) { asset in
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                        .overlay { PhotoThumbnailView(id: asset.id) }
                        .clipped()
                }
            }
        }
    }

    private var limitedPhotoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(store.photos) { asset in
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                        .overlay { PhotoThumbnailView(id: asset.id) }
                        .clipped()
                }
            }
            limitedBannerView
        }
    }

    private var limitedBannerView: some View {
        VStack(spacing: 12) {
            Text("접근 가능한 사진이 제한되어 있어요")
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
            Label("사진에 접근할 권한이 없어요", systemImage: "photo.slash")
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
}
