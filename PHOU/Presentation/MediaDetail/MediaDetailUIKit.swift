//
//  MediaDetailUIKit.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import SwiftUI
import UIKit
import AVFoundation
import QuartzCore

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .black
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerContainerView, context: Context) {
        if view.playerLayer.player !== player {
            view.playerLayer.player = player
        }
    }
}

final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            fatalError("Expected AVPlayerLayer backing layer")
        }
        return layer
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let resetID: String
    let containerSize: CGSize
    let isDetailsPanelPresented: Bool
    let backgroundColor: UIColor
    let onSingleTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LayoutAwareScrollView {
        let scrollView = LayoutAwareScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.decelerationRate = .fast
        scrollView.isScrollEnabled = false
        scrollView.bouncesZoom = true
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = backgroundColor
        scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.configure(scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: LayoutAwareScrollView, context: Context) {
        context.coordinator.update(
            image: image,
            resetID: resetID,
            containerSize: containerSize,
            isDetailsPanelPresented: isDetailsPanelPresented,
            backgroundColor: backgroundColor,
            onSingleTap: onSingleTap,
            in: scrollView
        )
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        private let imageView = UIImageView()
        private var currentResetID: String?
        private var lastContainerSize: CGSize = .zero
        private var lastDetailsPanelPresented: Bool?
        private var smoothCenteringDeadline: CFTimeInterval = 0
        private var onSingleTap: (() -> Void)?

        func configure(_ scrollView: UIScrollView) {
            imageView.contentMode = .scaleAspectFit
            scrollView.addSubview(imageView)

            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTapGesture.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(doubleTapGesture)

            let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
            singleTapGesture.require(toFail: doubleTapGesture)
            scrollView.addGestureRecognizer(singleTapGesture)
        }

        func update(
            image: UIImage,
            resetID: String,
            containerSize: CGSize,
            isDetailsPanelPresented: Bool,
            backgroundColor: UIColor,
            onSingleTap: @escaping () -> Void,
            in scrollView: LayoutAwareScrollView
        ) {
            scrollView.layoutIfNeeded()
            let effectiveContainerSize = resolvedContainerSize(
                requestedSize: containerSize,
                actualSize: scrollView.bounds.size
            )
            let needsReset = currentResetID != resetID || !isSameSize(lastContainerSize, effectiveContainerSize)
            currentResetID = resetID
            lastContainerSize = effectiveContainerSize
            self.onSingleTap = onSingleTap
            scrollView.decelerationRate = .fast

            if MediaDetailRevealGeometry.shouldSmoothCenteringAfterDetailsDismissal(
                wasDetailsPresented: lastDetailsPanelPresented,
                isDetailsPresented: isDetailsPanelPresented,
                isAtMinimumZoom: isAtMinimumZoom(in: scrollView)
            ) {
                smoothCenteringDeadline = CACurrentMediaTime() + 0.35
            }
            lastDetailsPanelPresented = isDetailsPanelPresented

            imageView.image = image
            scrollView.backgroundColor = backgroundColor
            scrollView.onLayout = { [weak self] updatedScrollView in
                self?.handleLayout(of: updatedScrollView)
            }

            if needsReset {
                resetZoom(in: scrollView, image: image, containerSize: effectiveContainerSize)
            }
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.isScrollEnabled = scrollView.zoomScale > scrollView.minimumZoomScale + 0.001
            centerImage(in: scrollView, animated: shouldAnimateCentering(in: scrollView))
        }

        private func resetZoom(in scrollView: UIScrollView, image: UIImage, containerSize: CGSize) {
            let safeWidth = max(containerSize.width, 1)
            let safeHeight = max(containerSize.height, 1)
            let widthScale = safeWidth / max(image.size.width, 1)
            let heightScale = safeHeight / max(image.size.height, 1)
            let fittingScale = min(widthScale, heightScale)
            let fittedSize = CGSize(
                width: max(image.size.width * fittingScale, 1),
                height: max(image.size.height * fittingScale, 1)
            )

            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 4
            scrollView.zoomScale = 1
            scrollView.isScrollEnabled = false

            imageView.frame = MediaDetailRevealGeometry.centeredFrame(
                contentSize: fittedSize,
                boundsSize: scrollView.bounds.size
            )
            scrollView.contentSize = imageView.frame.size
            scrollView.contentOffset = .zero
            scrollView.layoutIfNeeded()
            centerImage(in: scrollView, animated: shouldAnimateCentering(in: scrollView))
        }

        private func handleLayout(of scrollView: UIScrollView) {
            let effectiveContainerSize = resolvedContainerSize(
                requestedSize: lastContainerSize,
                actualSize: scrollView.bounds.size
            )

            guard !isSameSize(effectiveContainerSize, lastContainerSize) else {
                return
            }

            lastContainerSize = effectiveContainerSize

            guard
                scrollView.zoomScale <= scrollView.minimumZoomScale + 0.001,
                let image = imageView.image
            else {
                centerImage(in: scrollView, animated: shouldAnimateCentering(in: scrollView))
                return
            }

            resetZoom(in: scrollView, image: image, containerSize: effectiveContainerSize)
        }

        private func resolvedContainerSize(requestedSize: CGSize, actualSize: CGSize) -> CGSize {
            let width = actualSize.width > 0 ? actualSize.width : requestedSize.width
            let height = actualSize.height > 0 ? actualSize.height : requestedSize.height
            return CGSize(
                width: max(width.rounded(.toNearestOrAwayFromZero), 1),
                height: max(height.rounded(.toNearestOrAwayFromZero), 1)
            )
        }

        private func isSameSize(_ lhs: CGSize, _ rhs: CGSize) -> Bool {
            abs(lhs.width - rhs.width) < 1 && abs(lhs.height - rhs.height) < 1
        }

        private func isAtMinimumZoom(in scrollView: UIScrollView) -> Bool {
            scrollView.zoomScale <= scrollView.minimumZoomScale + 0.001
        }

        private func shouldAnimateCentering(in scrollView: UIScrollView) -> Bool {
            isAtMinimumZoom(in: scrollView) && CACurrentMediaTime() <= smoothCenteringDeadline
        }

        private func centerImage(in scrollView: UIScrollView, animated: Bool = false) {
            let boundsSize = scrollView.bounds.size
            let frameToCenter = MediaDetailRevealGeometry.centeredFrame(
                contentSize: imageView.frame.size,
                boundsSize: boundsSize
            )

            guard imageView.frame != frameToCenter else { return }

            let changes = {
                self.imageView.frame = frameToCenter
            }

            if animated {
                UIView.animate(
                    withDuration: 0.24,
                    delay: 0,
                    options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut],
                    animations: changes
                )
            } else {
                UIView.performWithoutAnimation(changes)
            }
        }

        @objc
        private func handleSingleTap() {
            onSingleTap?()
        }

        @objc
        private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                scrollView.isScrollEnabled = false
                return
            }

            let tapPoint = gesture.location(in: imageView)
            let zoomScale = min(scrollView.maximumZoomScale, 2.5)
            let zoomWidth = scrollView.bounds.width / zoomScale
            let zoomHeight = scrollView.bounds.height / zoomScale
            let zoomRect = CGRect(
                x: tapPoint.x - (zoomWidth / 2),
                y: tapPoint.y - (zoomHeight / 2),
                width: zoomWidth,
                height: zoomHeight
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

final class LayoutAwareScrollView: UIScrollView {
    var onLayout: ((UIScrollView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(self)
    }
}
