//
//  AlbumView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import SwiftUI
import ComposableArchitecture

struct AlbumView: View {
    @Bindable var store: StoreOf<AlbumFeature>

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("앨범")
                .onAppear { store.send(.view(.onAppear)) }
                .navigationDestination(
                    item: $store.scope(state: \.albumPhotoGrid, action: \.albumPhotoGrid)
                ) { gridStore in
                    AlbumPhotoGridView(store: gridStore)
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
        case .authorized, .limited:
            if store.isLoading && store.albums.isEmpty {
                loadingView
            } else {
                albumList
            }
        }
    }

    private var albumList: some View {
        let smartAlbums = store.albums.filter { $0.albumType == .smartAlbum }
        let userAlbums = store.albums.filter { $0.albumType == .userAlbum }

        return List {
            if !smartAlbums.isEmpty {
                Section("시스템 앨범") {
                    ForEach(smartAlbums) { album in
                        albumRow(album)
                    }
                }
            }
            if !userAlbums.isEmpty {
                Section("나의 앨범") {
                    ForEach(userAlbums) { album in
                        albumRow(album)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func albumRow(_ album: AlbumGroup) -> some View {
        Button {
            store.send(.view(.albumTapped(album)))
        } label: {
            HStack(spacing: 12) {
                Group {
                    if let coverAssetId = album.coverAssetId {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                PhotoThumbnailView(
                                    id: coverAssetId,
                                    targetSize: CGSize(width: 60, height: 60)
                                )
                            }
                            .clipped()
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(uiColor: .secondarySystemBackground))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("\(album.assetCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .alignmentGuide(.listRowSeparatorTrailing) { dimensions in
            dimensions.width
        }
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
