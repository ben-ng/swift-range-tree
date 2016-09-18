//
//  Int+RangeTreePoint.swift
//  Pods
//
//  Created by Benjamin Ng on 9/18/16.
//
//

import Foundation

extension Int: RangeTreePoint {
    public typealias Position = Int
    public static var dimensions = 1
    public func positionIn(dimension: Int) -> Position {
        return self
    }
}
