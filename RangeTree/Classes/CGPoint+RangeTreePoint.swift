//
//  CGPoint+RangeTreePoint.swift
//  Pods
//
//  Created by Benjamin Ng on 9/18/16.
//
//

import Foundation

extension CGPoint: RangeTreePoint {
    public typealias Position = CGFloat
    public static var dimensions = 2
    public func positionIn(dimension: Int) -> Position {
        return dimension == 0 ? self.x : self.y
    }
}
