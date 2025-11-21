//
//  Item.swift
//  Dirty RAW
//
//  Created by 莳昇 on 2025/11/21.
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
