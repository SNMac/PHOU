//
//  MediaDetailRevealGeometry.swift
//  PHOU
//
//  Created by Codex on 4/30/26.
//

import CoreGraphics

struct MediaDetailRevealGeometry {
    static func pageContentLiftOffset(isDetailsPresented: Bool, mediaLift: CGFloat) -> CGFloat {
        guard isDetailsPresented else { return 0 }
        return -max(mediaLift, 0)
    }

    static func shouldSmoothCenteringAfterDetailsDismissal(
        wasDetailsPresented: Bool?,
        isDetailsPresented: Bool,
        isAtMinimumZoom: Bool
    ) -> Bool {
        wasDetailsPresented == true && !isDetailsPresented && isAtMinimumZoom
    }

    static func centeredFrame(contentSize: CGSize, boundsSize: CGSize) -> CGRect {
        CGRect(
            x: contentSize.width < boundsSize.width ? (boundsSize.width - contentSize.width) / 2 : 0,
            y: contentSize.height < boundsSize.height ? (boundsSize.height - contentSize.height) / 2 : 0,
            width: contentSize.width,
            height: contentSize.height
        )
    }
}
