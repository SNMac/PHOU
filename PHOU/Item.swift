//
//  Item.swift
//  PHOU
//
//  Created by 서동환 on 5/18/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
