//
//  MediaDetailAssetLoader.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import UIKit
import AVFoundation
import CoreLocation
import ImageIO
@preconcurrency import Photos

enum MediaDetailAssetLoader {
    nonisolated(unsafe) private static let assetCache = NSCache<NSString, PHAsset>()
    nonisolated(unsafe) private static let imageCache = NSCache<NSString, UIImage>()
    nonisolated(unsafe) private static let locationCache = NSCache<NSString, NSString>()
    nonisolated(unsafe) private static let deviceCache = NSCache<NSString, NSString>()

    static func displayImage(for assetID: String, targetSize: CGSize) async -> UIImage? {
        let requestSize = await pixelSize(from: targetSize)
        let cacheKey = imageCacheKey(assetID: assetID, requestSize: requestSize)
        if let cached = imageCache.object(forKey: cacheKey as NSString) {
            return cached
        }

        guard let asset = asset(for: assetID) else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        if let image = await MediaDetailPhotoKitBridge.requestImage(
            for: asset,
            targetSize: requestSize,
            contentMode: .aspectFit,
            options: options
        ) {
            imageCache.setObject(image, forKey: cacheKey as NSString)
            return image
        }

        return nil
    }

    static func playerItem(for assetID: String) async -> AVPlayerItem? {
        guard let asset = asset(for: assetID) else { return nil }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic

        return await MediaDetailPhotoKitBridge.requestPlayerItem(for: asset, options: options)
    }

    static func summaryDetails(for asset: PhotoAsset) async -> MediaAssetDetails {
        guard let phAsset = self.asset(for: asset.id) else {
            return .placeholder(for: asset)
        }

        let captureDate = phAsset.creationDate ?? asset.creationDate
        let locationText = await resolvedLocationText(for: asset.id, location: phAsset.location)
        let title = MediaAssetDetails.titleTexts(
            date: captureDate,
            locationText: locationText == "위치 없음" ? nil : locationText
        )

        return MediaAssetDetails(
            id: asset.id,
            titlePrimaryText: title.primary,
            titleSecondaryText: title.secondary,
            captureDateText: MediaAssetDetails.formattedInfoDate(captureDate),
            locationText: locationText,
            filenameText: resolvedFilename(for: phAsset),
            deviceText: "상세정보에서 확인 가능",
            albumText: "상세정보에서 확인 가능",
            isFavorite: phAsset.isFavorite,
            mediaTypeText: MediaAssetDetails.mediaTypeText(asset.mediaType),
            pixelSizeText: "\(phAsset.pixelWidth) × \(phAsset.pixelHeight)"
        )
    }

    // Returns a provisional summary without accessing any PHAsset or PHAssetResource properties,
    // preventing PHAssetOriginalMetadataProperties faults on the main thread.
    // Uses only PhotoAsset values and the already-resolved locationCache.
    // The async summaryDetails/details tasks fill in real data immediately after.
    static func provisionalSummaryDetails(for asset: PhotoAsset) -> MediaAssetDetails {
        let captureDate = asset.creationDate
        let cachedLocation = locationCache.object(forKey: asset.id as NSString) as String?
        let hasKnownLocation = cachedLocation.map { $0 != "위치 없음" } ?? false

        let title = MediaAssetDetails.provisionalTitleTexts(
            date: captureDate,
            hasLocation: hasKnownLocation
        )

        return MediaAssetDetails(
            id: asset.id,
            titlePrimaryText: title.primary,
            titleSecondaryText: title.secondary,
            captureDateText: MediaAssetDetails.formattedInfoDate(captureDate),
            locationText: cachedLocation ?? "위치 확인 중",
            filenameText: "정보 확인 중",
            deviceText: "상세정보에서 확인 가능",
            albumText: "상세정보에서 확인 가능",
            isFavorite: asset.isFavorite,
            mediaTypeText: MediaAssetDetails.mediaTypeText(asset.mediaType),
            pixelSizeText: "-"
        )
    }

    static func details(for asset: PhotoAsset, summary existingSummary: MediaAssetDetails? = nil) async -> MediaAssetDetails {
        guard let phAsset = self.asset(for: asset.id) else {
            return .placeholder(for: asset)
        }

        let summary = if let existingSummary {
            existingSummary
        } else {
            await summaryDetails(for: asset)
        }
        async let deviceTextTask = resolvedDeviceText(for: asset.id)
        async let albumTextTask = resolvedAlbumText(for: phAsset)

        return MediaAssetDetails(
            id: summary.id,
            titlePrimaryText: summary.titlePrimaryText,
            titleSecondaryText: summary.titleSecondaryText,
            captureDateText: summary.captureDateText,
            locationText: summary.locationText,
            filenameText: summary.filenameText,
            deviceText: await deviceTextTask,
            albumText: await albumTextTask,
            isFavorite: summary.isFavorite,
            mediaTypeText: summary.mediaTypeText,
            pixelSizeText: summary.pixelSizeText
        )
    }

    static func shareItems(for asset: PhotoAsset) async -> [Any]? {
        guard let phAsset = self.asset(for: asset.id) else { return nil }

        switch asset.mediaType {
        case .image, .unknown:
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            guard let image = await MediaDetailPhotoKitBridge.requestImage(
                for: phAsset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) else { return nil }
            return [image]

        case .video:
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            guard let url = await MediaDetailPhotoKitBridge.requestVideoURL(for: phAsset, options: options) else {
                return nil
            }
            return [url]
        }
    }

    static func asset(for assetID: String) -> PHAsset? {
        let cacheKey = assetID as NSString
        if let cached = assetCache.object(forKey: cacheKey) {
            return cached
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        assetCache.setObject(asset, forKey: cacheKey)
        return asset
    }

    private static func resolvedLocationText(for assetID: String, location: CLLocation?) async -> String {
        if let cached = locationCache.object(forKey: assetID as NSString) {
            return cached as String
        }

        guard let location else {
            locationCache.setObject("위치 없음", forKey: assetID as NSString)
            return "위치 없음"
        }

        let fallback = coordinateText(for: location)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let resolved = detailedLocationText(from: placemark) ?? fallback
                locationCache.setObject(resolved as NSString, forKey: assetID as NSString)
                return resolved
            }
        } catch {
            // Fall through to coordinates.
        }

        locationCache.setObject(fallback as NSString, forKey: assetID as NSString)
        return fallback
    }

    private static func detailedLocationText(from placemark: CLPlacemark) -> String? {
        let administrativeArea = normalizedText(placemark.administrativeArea)
        let locality = normalizedText(placemark.locality)
        let subLocality = normalizedText(placemark.subLocality)
        let thoroughfare = normalizedText(placemark.thoroughfare)
        let name = normalizedText(placemark.name)

        let prefersAdministrativeArea = administrativeArea.map {
            $0.contains("특별시") || $0.contains("광역시") || $0.contains("특별자치시")
        } ?? false

        let primary = prefersAdministrativeArea
            ? (administrativeArea ?? locality)
            : (locality ?? administrativeArea)

        let neighborhood = preferredNeighborhoodText(subLocality: subLocality, name: name)

        let secondary = [neighborhood, thoroughfare, name]
            .compactMap { $0 }
            .first { candidate in
                guard let primary else { return !candidate.isEmpty }
                return candidate != primary && !candidate.contains(primary)
            }

        if let primary, let secondary {
            return "\(primary) - \(secondary)"
        }

        return primary ?? secondary
    }

    private static func preferredNeighborhoodText(subLocality: String?, name: String?) -> String? {
        guard let subLocality else {
            return neighborhoodLikeText(from: name)
        }

        guard
            let name,
            isMoreSpecificNeighborhood(name, than: subLocality)
        else {
            return subLocality
        }

        return name
    }

    private static func neighborhoodLikeText(from value: String?) -> String? {
        guard let value else { return nil }
        let suffixes = ["동", "가", "리", "읍", "면"]
        return suffixes.contains(where: value.hasSuffix) ? value : nil
    }

    private static func isMoreSpecificNeighborhood(_ candidate: String, than base: String) -> Bool {
        let normalizedCandidate = candidate.replacingOccurrences(
            of: "\\d+",
            with: "",
            options: .regularExpression
        )
        let normalizedBase = base.replacingOccurrences(
            of: "\\d+",
            with: "",
            options: .regularExpression
        )

        guard normalizedCandidate == normalizedBase else { return false }
        return candidate != base
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func resolvedFilename(for asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let preferred = resources.first { resource in
            switch resource.type {
            case .fullSizePhoto, .photo, .fullSizeVideo, .video:
                return true
            default:
                return false
            }
        }

        return preferred?.originalFilename ?? resources.first?.originalFilename ?? "파일명 없음"
    }

    private static func resolvedAlbumText(for asset: PHAsset) -> String {
        var titles: [String] = []

        for collectionType in [PHAssetCollectionType.smartAlbum, .album] {
            let collections = PHAssetCollection.fetchAssetCollectionsContaining(
                asset,
                with: collectionType,
                options: nil
            )

            collections.enumerateObjects { collection, _, _ in
                guard let title = normalizedText(collection.localizedTitle) else { return }
                if !titles.contains(title) {
                    titles.append(title)
                }
            }
        }

        return titles.isEmpty ? "앨범 정보 없음" : titles.joined(separator: ", ")
    }

    private static func resolvedDeviceText(for assetID: String) async -> String {
        if let cached = deviceCache.object(forKey: assetID as NSString) {
            return cached as String
        }

        let resolved = await Task.detached(priority: .utility) { () -> String in
            guard
                let asset = self.asset(for: assetID),
                asset.mediaType == .image
            else {
                return "정보 없음"
            }

            let resourceOptions = PHAssetResourceRequestOptions()
            resourceOptions.isNetworkAccessAllowed = false

            guard
                let resource = preferredImageResource(for: asset),
                let metadata = await MediaDetailPhotoKitBridge.requestImageDeviceMetadata(
                    for: resource,
                    options: resourceOptions
                )
            else {
                return "정보 없음"
            }

            guard
                let deviceText = resolvedDeviceText(from: metadata)
            else {
                return "정보 없음"
            }

            return deviceText
        }.value

        deviceCache.setObject(resolved as NSString, forKey: assetID as NSString)
        return resolved
    }

    private static func preferredImageResource(for asset: PHAsset) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        return resources.first { resource in
            switch resource.type {
            case .fullSizePhoto, .photo:
                return true
            default:
                return false
            }
        } ?? resources.first
    }

    private static func resolvedDeviceText(from metadata: MediaDetailPhotoKitBridge.ImageDeviceMetadata) -> String? {
        let make = normalizedText(
            metadata.make ?? metadata.ownerName
        )
        let model = normalizedText(metadata.model)

        if let model, let make {
            return model.contains(make) ? model : "\(make) \(model)"
        }

        return model ?? make
    }

    private static func coordinateText(for location: CLLocation) -> String {
        let latitude = String(format: "%.4f", location.coordinate.latitude)
        let longitude = String(format: "%.4f", location.coordinate.longitude)
        return "\(latitude), \(longitude)"
    }

    private static func imageCacheKey(assetID: String, requestSize: CGSize) -> String {
        "\(assetID)-\(Int(requestSize.width))x\(Int(requestSize.height))"
    }

    @MainActor
    private static func pixelSize(from size: CGSize) -> CGSize {
        let scale = max(UIScreen.main.scale, 1)
        return CGSize(width: max(size.width * scale, 1), height: max(size.height * scale, 1))
    }
}
