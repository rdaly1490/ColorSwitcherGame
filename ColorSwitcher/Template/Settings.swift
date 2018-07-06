//
//  Settings.swift
//  ColorSwitcher
//
//  Created by Rob Daly on 7/5/18.
//  Copyright © 2018 Rob Daly. All rights reserved.
//

import SpriteKit

//physicsBody.categoryBitMask expects a UInt32
struct PhysicsCategories {
    static let none: UInt32 = 0 // No physics
    static let ballCategory: UInt32 = 0x1 // 01
    static let colorCircleCategory: UInt32 = 0x1 << 1 // 10
}

struct ZPositions {
    static let label: CGFloat = 0
    static let ball: CGFloat = 1
    static let colorCircle: CGFloat = 2
}
