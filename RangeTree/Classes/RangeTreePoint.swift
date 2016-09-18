//
//  RangeTreePoint.swift
//  Pods
//
//  Created by Benjamin Ng on 9/17/16.
//
//

import Foundation

public protocol RangeTreePoint {
    associatedtype Position: Comparable
    static var dimensions: Int { get}
    func positionIn(dimension: Int) -> Position
}
