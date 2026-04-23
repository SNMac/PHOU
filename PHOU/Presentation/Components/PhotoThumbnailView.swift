//
//  PhotoThumbnailView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import SwiftUI
import UIKit
@preconcurrency import Photos

struct PhotoThumbnailView: View {
    let id: String
    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    private static let imageManager = PHCachingImageManager()

    private static var targetSize: CGSize {
        let cellWidth = floor(UIScreen.main.bounds.width / 3)
        let scale = UIScreen.main.scale
        let length = cellWidth * scale
        return CGSize(width: length, height: length)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
        .task(id: id) {
            image = await loadThumbnail()
        }
        .onDisappear {
            cancelThumbnailRequest()
            image = nil
        }
    }

    private func loadThumbnail() async -> UIImage? {
        cancelThumbnailRequest()

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            var resumed = false
            requestID = Self.imageManager.requestImage(
                for: asset,
                targetSize: Self.targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, info in
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                guard !isCancelled else { return }
                guard !resumed else { return }
                resumed = true
                requestID = nil
                continuation.resume(returning: result)
            }
        }
    }

    private func cancelThumbnailRequest() {
        guard let requestID else { return }
        Self.imageManager.cancelImageRequest(requestID)
        self.requestID = nil
    }
}
