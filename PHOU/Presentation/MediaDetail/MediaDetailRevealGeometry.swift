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
}
