//
//  Double+RangeTreePoint.swift
//  Pods
//
//  Created by Benjamin Ng on 9/17/16.
//
//

import Foundation

extension Double: RangeTreePoint {
    public typealias Position = Double
    public static var dimensions = 1
    public func positionIn(dimension: Int) -> Position {
        return self
    }
}
