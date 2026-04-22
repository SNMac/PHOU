//
//  GalleryView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import ComposableArchitecture
import SwiftUI

struct GalleryView: View {
    let store: StoreOf<GalleryFeature>

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 2)]

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

        case .authorized, .limited:
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
                    PhotoThumbnailView(id: asset.id)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("사진 접근 권한 없음", systemImage: "photo.slash")
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
