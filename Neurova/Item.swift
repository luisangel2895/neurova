//
//  Item.swift
//  Neurova
//
//  Created by Angel Orellana on 2/03/26.
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
