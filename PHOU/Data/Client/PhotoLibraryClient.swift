//
//  PhotoLibraryClient.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

@preconcurrency import Photos
import ComposableArchitecture

@DependencyClient
struct PhotoLibraryClient: Sendable {
    var requestAuthorization: @Sendable () async -> PhotoAuthStatus = { .notDetermined }
    var fetchPhotos: @Sendable () async throws -> [PhotoAsset] = { [] }
    var fetchAlbums: @Sendable () async throws -> [AlbumGroup] = { [] }
    var deleteAssets: @Sendable (_ ids: [String]) async throws -> Void = { _ in }
}

extension PhotoLibraryClient: DependencyKey {
    static let liveValue = PhotoLibraryClient(
        requestAuthorization: {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return PhotoAuthStatus(from: status)
        },
        fetchPhotos: {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let result = PHAsset.fetchAssets(with: .image, options: options)
            var assets: [PhotoAsset] = []
            result.enumerateObjects { asset, _, _ in
                assets.append(PhotoAsset(
                    id: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    isFavorite: asset.isFavorite,
                    mediaType: .image
                ))
            }
            return assets
        },
        fetchAlbums: {
            var albums: [AlbumGroup] = []
            let smartResult = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum, subtype: .any, options: nil
            )
            smartResult.enumerateObjects { collection, _, _ in
                let count = PHAsset.fetchAssets(in: collection, options: nil).count
                albums.append(AlbumGroup(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "",
                    assetCount: count,
                    albumType: .smartAlbum
                ))
            }
            let userResult = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: nil
            )
            userResult.enumerateObjects { collection, _, _ in
                let count = PHAsset.fetchAssets(in: collection, options: nil).count
                albums.append(AlbumGroup(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "",
                    assetCount: count,
                    albumType: .userAlbum
                ))
            }
            return albums
        },
        deleteAssets: { ids in
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var targets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in targets.append(asset) }
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(targets as NSArray)
            }
        }
    )

    static let previewValue = PhotoLibraryClient(
        requestAuthorization: { .authorized },
        fetchPhotos: {
            (0..<12).map { i in
                PhotoAsset(
                    id: "preview-\(i)",
                    creationDate: Calendar.current.date(byAdding: .day, value: -i, to: Date()),
                    isFavorite: i == 0,
                    mediaType: .image
                )
            }
        },
        fetchAlbums: {
            [
                AlbumGroup(id: "recents", title: "최근 항목", assetCount: 12, albumType: .smartAlbum),
                AlbumGroup(id: "favorites", title: "즐겨찾기", assetCount: 1, albumType: .smartAlbum)
            ]
        },
        deleteAssets: { _ in }
    )
}

extension DependencyValues {
    var photoLibraryClient: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}

private extension PhotoAuthStatus {
    init(from status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized:    self = .authorized
        case .limited:       self = .limited
        case .denied:        self = .denied
        case .restricted:    self = .restricted
        @unknown default:    self = .denied
        }
    }
}
