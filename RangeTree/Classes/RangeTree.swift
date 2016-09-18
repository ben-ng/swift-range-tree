//
//  RangeTree.swift
//  Pods
//
//  Created by Benjamin Ng on 9/18/16.
//
//

import Foundation

internal class RangeTree<Point: RangeTreePoint>: CustomDebugStringConvertible {
    private var rootNode: RangeTreeNode<Point>
    var debugDescription: String {
        get {
            return rootNode.debugDescription
        }
    }
    
    required init(values: [Point]) {
        rootNode = RangeTreeNode<Point>(dimension: 0, values: values)
    }
    
    func insert(_ newPoint: Point) {
        rootNode = rootNode.insert(dimension: 0, value: newPoint)
    }
    
    func valuesInRange(rangePerDimension: (Point.Position, Point.Position)...) -> [Point] {
        assert(rangePerDimension.count == Point.dimensions, "The number of ranges must match the number of dimensions")
        
        return rootNode.valuesIn(rangePerDimension: rangePerDimension.suffix(from: rangePerDimension.startIndex))
    }
}

fileprivate enum Direction {
    case Left
    case Right
}

fileprivate enum RangeTreeNode<Point: RangeTreePoint>: CustomDebugStringConvertible {
    case MinSentinel()
    case MaxSentinel()
    indirect case Leaf(position: Point.Position, values: [Point], nextDimension: RangeTreeNode<Point>?)
    indirect case InternalNode(left: RangeTreeNode<Point>, right: RangeTreeNode<Point>, limits: (Point.Position?, Point.Position?), weight: Int, nextDimension: RangeTreeNode<Point>?)
    
    var values: [Point] {
        get {
            switch self {
            case .MinSentinel():
                return []
            case .MaxSentinel():
                return []
            case let .Leaf(_, values, _):
                return values
            case let .InternalNode(left, right, _, _, _):
                return left.values + right.values
            }
        }
    }
    
    var weight: Int {
        get {
            switch self {
            case .MinSentinel():
                return 1
            case .MaxSentinel():
                return 1
            case let .Leaf(_, values, _):
                return 1
            case let .InternalNode(left, right, _, _, _):
                return left.weight + right.weight
            }
        }
    }
    
    var debugDescription: String {
        get {
            return values.map({"\($0)"}).joined(separator: " ")
        }
    }
    
    init(dimension onDimension: Int, values: [Point]) {
        let sortedValues = values.sorted {$0.positionIn(dimension: onDimension) < $1.positionIn(dimension: onDimension)}
        var lastValuePosition: Point.Position?
        var lastValueBucket = [Point]()
        var processed: [(Point.Position, [Point])] = []
        for value in sortedValues {
            let pos = value.positionIn(dimension: onDimension)
            let shouldAppendToLastBucket = lastValuePosition != nil && lastValuePosition == pos
            
            if shouldAppendToLastBucket {
                lastValueBucket.append(value)
            }
            else {
                if let lastValuePosition = lastValuePosition {
                    processed.append((lastValuePosition, lastValueBucket))
                }
                lastValueBucket = [value]
                lastValuePosition = pos
            }
        }
        if let lastValuePosition = lastValuePosition {
            processed.append((lastValuePosition, lastValueBucket))
        }
        self.init(dimension: onDimension, presortedValueBuckets: ArraySlice<(Point.Position, [Point])>(processed))
    }
    
    init(dimension onDimension: Int, presortedValueBuckets buckets: ArraySlice<(Point.Position, [Point])>) {
        let hasNextDimension = onDimension < Point.dimensions - 1
        
        if buckets.count == 0 {
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, values: []) :
                nil
            self = .InternalNode(left: .MinSentinel(), right: .MaxSentinel(), limits: (nil, nil), weight: 2, nextDimension: nextDimension)
        }
        else if buckets.count == 1 {
            let (leafPosition, leafValues) = buckets.first!
            
            // Note that the same next dimension tree can be used for the internal node as well as the leaf node; there's
            // only one value in both cases, and it's the same value.
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, values: leafValues) :
                nil
            let leafNode: RangeTreeNode<Point> = .Leaf(position: leafPosition, values: leafValues, nextDimension: nextDimension)
            
            if buckets.startIndex == 0 {
                self = .InternalNode(left: .MinSentinel(), right: leafNode, limits: (nil, leafPosition), weight: 2, nextDimension: nextDimension)
            }
            else if buckets.startIndex == buckets.count - 1 {
                self = .InternalNode(left: leafNode, right: .MaxSentinel(), limits: (leafPosition, nil), weight: 2, nextDimension: nextDimension)
            }
            else {
                self = leafNode
            }
        }
        else {
            let midIndex = buckets.startIndex + buckets.count / 2
            let leftRange = buckets[buckets.startIndex..<midIndex]
            let rightRange = buckets.suffix(from: midIndex)
            let leftTreeMax: Point.Position? = buckets.count == 0 ? nil : leftRange.last!.0
            let rightTreeMin: Point.Position? = buckets.count == 0 ? nil : rightRange.first!.0
            let leftTree = RangeTreeNode<Point>.init(dimension: onDimension, presortedValueBuckets: leftRange)
            let rightTree = RangeTreeNode<Point>.init(dimension: onDimension, presortedValueBuckets: rightRange)
            let values = buckets.map({$0.1}).reduce([], +)
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, values: values) :
                nil
            self = .InternalNode(left: leftTree, right: rightTree, limits: (leftTreeMax, rightTreeMin), weight: leftTree.weight + rightTree.weight, nextDimension: nextDimension)
        }
    }
    
    func insert(dimension onDimension: Int, value newValue: Point) -> RangeTreeNode {
        let hasNextDimension = onDimension < Point.dimensions - 1
        let newPosition = newValue.positionIn(dimension: onDimension)
        
        switch self {
        case .MinSentinel():
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, values: [newValue]) :
            nil
            let right: RangeTreeNode<Point> = .Leaf(position: newPosition, values: [newValue], nextDimension: nextDimension)
            return .InternalNode(left: .MinSentinel(), right: right, limits: (nil, newPosition), weight: 2, nextDimension: nextDimension)
            
        case .MaxSentinel():
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, values: [newValue]) :
            nil
            let left: RangeTreeNode<Point> = .Leaf(position: newPosition, values: [newValue], nextDimension: nextDimension)
            return .InternalNode(left: left, right: .MaxSentinel(), limits: (newPosition, nil), weight: 2, nextDimension: nextDimension)
            
        case let .Leaf(oldPosition, oldValues, oldNextDimension):
            // If a leaf for this position already exists, append the value to the leaf
            if newPosition == oldPosition {
                let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                    RangeTreeNode<Point>(dimension: onDimension + 1, values: oldValues + [newValue]) :
                    nil
                return .Leaf(position: oldPosition, values: oldValues + [newValue], nextDimension: nextDimension)
            }
            // Otherwise, split the existing leaf up by turning it into an internal node
            else {
                let nextLeafDimension: RangeTreeNode<Point>? = hasNextDimension ?
                    RangeTreeNode<Point>(dimension: onDimension + 1, values: [newValue]) :
                    nil
                let nextInternalNodeDimension: RangeTreeNode<Point>? = hasNextDimension ?
                    RangeTreeNode<Point>(dimension: onDimension + 1, values: oldValues + [newValue]) :
                    nil
                
                if newPosition < oldPosition {
                    let left: RangeTreeNode<Point> = .Leaf(position: newPosition, values: [newValue], nextDimension: nextLeafDimension)
                    let right: RangeTreeNode<Point> = .Leaf(position: oldPosition, values: oldValues, nextDimension: oldNextDimension)
                    return .InternalNode(left: left, right: right, limits: (newPosition, oldPosition), weight: 2, nextDimension: nextInternalNodeDimension)
                }
                else if newPosition > oldPosition {
                    let left: RangeTreeNode<Point> = .Leaf(position: oldPosition, values: oldValues, nextDimension: oldNextDimension)
                    let right: RangeTreeNode<Point> = .Leaf(position: newPosition, values: [newValue], nextDimension: nextLeafDimension)
                    return .InternalNode(left: left, right: right, limits: (oldPosition, newPosition), weight: 2, nextDimension: nextInternalNodeDimension)
                }
                else {
                    assertionFailure("This case should have been handled earlier")
                    return self
                }
            }
            
        case let .InternalNode(left, right, (leftTreeMax, rightTreeMin), weight, _):
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, values: left.values + right.values + [newValue]) :
                nil
            
            if lte(newPosition, leftTreeMax) {
                return .InternalNode(left: left.insert(dimension: onDimension, value: newValue), right: right, limits: (leftTreeMax, rightTreeMin), weight: weight + 1, nextDimension: nextDimension)
            }
            else if gte(newPosition, rightTreeMin) {
                return .InternalNode(left: left, right: right.insert(dimension: onDimension, value: newValue), limits: (leftTreeMax, rightTreeMin), weight: weight + 1, nextDimension: nextDimension)
            }
            // If the new position sits between the max of the left tree and the min of the right tree, (arbitrarily) insert
            // it on the left subtree, taking care to update the max of the left tree to the new position
            else {
                return .InternalNode(left: left.insert(dimension: onDimension, value: newValue), right: right, limits: (newPosition, rightTreeMin), weight: weight + 1, nextDimension: nextDimension)
            }
        }
    }
    
    func valuesIn(rangePerDimension: ArraySlice<(Point.Position, Point.Position)>) -> [Point] {
        assert(rangePerDimension.count > 0)
        
        let (min, max) = rangePerDimension.first!
        
        if case let .MinSentinel() = self {
            return []
        }
        if case let .MaxSentinel() = self {
            return []
        }
        
        if case let .Leaf(position, values, nextDimension) = self {
            if position < min || position > max {
                return []
            }
            if let nextDimension = nextDimension {
                return nextDimension.valuesIn(rangePerDimension: rangePerDimension.suffix(from: rangePerDimension.startIndex + 1))
            }
            else if rangePerDimension.count > 1 {
                assertionFailure("There was another dimension remaining, but no more ranges to filter on")
                return []
            }
            else {
                return values
            }
        }
        
        let predecessorPath = self.pathToPredecessor(of: min)
        let successorPath = self.pathToSuccessor(of: max)
        var commonPrefixLength: Int = 0
        while (commonPrefixLength < predecessorPath.count &&
            commonPrefixLength < successorPath.count &&
            predecessorPath[commonPrefixLength] == successorPath[commonPrefixLength]) {
            commonPrefixLength = commonPrefixLength + 1
        }
        let commonPrefix = predecessorPath.prefix(commonPrefixLength)
        let predecessorPathFromPrefix = predecessorPath.count > commonPrefixLength ?
            predecessorPath.suffix(from: commonPrefixLength + 1) :
            ArraySlice<Direction>()
        let successorPathFromPrefix = successorPath.count > commonPrefixLength ?
            successorPath.suffix(from: commonPrefixLength + 1) :
            ArraySlice<Direction>()
        let commonAncestor = nodeAtEndOfPath(path: commonPrefix)
        
        if case let .InternalNode(commonAncestorLeft, commonAncestorRight, _, _, _) = commonAncestor {
            let leftAnsNodes = commonAncestorLeft.nodesOnRightOfPath(path: predecessorPathFromPrefix)
            let rightAnsNodes = commonAncestorRight.nodesOnLeftOfPath(path: successorPathFromPrefix)
            var answerNodes = leftAnsNodes + rightAnsNodes
            // We need to check for the special cases where the children of the common ancestor are leaves
            // If so, add them as answer nodes, and then let the map function filter them out if they're invalid
            if case let .Leaf(position, _, _) = commonAncestorLeft {
                answerNodes.append(commonAncestorLeft)
            }
            if case let .Leaf(position, _, _) = commonAncestorRight {
                answerNodes.append(commonAncestorRight)
            }
            return answerNodes.map({ (node: RangeTreeNode<Point>) -> [Point] in
                switch node {
                case .MinSentinel():
                    return []
                case .MaxSentinel():
                    return []
                case let .Leaf(position, values, nextDimension):
                    if position < min || position > max {
                        return []
                    }
                    else if rangePerDimension.count == 1 {
                        return values
                    }
                    else if let nextDimension = nextDimension {
                        return nextDimension.valuesIn(rangePerDimension: rangePerDimension.suffix(from: rangePerDimension.startIndex + 1))
                    }
                    else {
                        assertionFailure("A Leaf is missing a required dimension")
                        return []
                    }
                case let .InternalNode(_, _, _, _, nextDimension):
                    if rangePerDimension.count == 1 {
                        return node.values
                    }
                    else if let nextDimension = nextDimension {
                        return nextDimension.valuesIn(rangePerDimension: rangePerDimension.suffix(from: rangePerDimension.startIndex + 1))
                    }
                    else {
                        assertionFailure("An InternalNode is missing a required dimension")
                        return []
                    }
                }
            }).reduce([], +)
        }
        
        if case let .Leaf(position, values, nextDimension) = commonAncestor {
            if position < min || position > max {
                return []
            }
            else if rangePerDimension.count == 1 {
                return values
            }
            else if let nextDimension = nextDimension {
                return nextDimension.valuesIn(rangePerDimension: rangePerDimension.suffix(from: rangePerDimension.startIndex + 1))
            }
            else {
                assertionFailure("A Leaf is missing a required dimension")
                return []
            }
        }
        
        return []
    }
    
    func nodesOnRightOfPath(path: ArraySlice<Direction>) -> [RangeTreeNode] {
        if path.count > 0 {
            switch self {
            case .MinSentinel():
                assertionFailure("Reached the MinSentinel, but path is non-empty")
            case .MaxSentinel():
                assertionFailure("Reached the MaxSentinel, but path is non-empty")
            case let .Leaf(_, _, _):
                assertionFailure("Reached a leaf node, but path is non-empty")
            case let .InternalNode(left, right, _, _, _):
                switch path.first! {
                case .Left:
                    return left.nodesOnRightOfPath(path: path.suffix(from: path.startIndex + 1)) + [right]
                case .Right:
                    return right.nodesOnRightOfPath(path: path.suffix(from: path.startIndex + 1))
                }
            }
            
            assertionFailure("Should have returned by now")
        }
        
        return []
    }
    
    func nodesOnLeftOfPath(path: ArraySlice<Direction>) -> [RangeTreeNode] {
        if path.count > 0 {
            switch self {
            case .MinSentinel():
                assertionFailure("Reached the MinSentinel, but path is non-empty")
            case .MaxSentinel():
                assertionFailure("Reached the MaxSentinel, but path is non-empty")
            case let .Leaf(_, _, _):
                assertionFailure("Reached a leaf node, but path is non-empty")
            case let .InternalNode(left, right, _, _, _):
                switch path.first! {
                case .Left:
                    return left.nodesOnLeftOfPath(path: path.suffix(from: path.startIndex + 1))
                case .Right:
                    return [left] + right.nodesOnLeftOfPath(path: path.suffix(from: path.startIndex + 1))
                }
            }
            
            assertionFailure("Should have returned by now")
        }
        
        return []
    }
    
    func nodeAtEndOfPath(path: ArraySlice<Direction>) -> RangeTreeNode {
        if path.count == 0 {
            return self
        }
        
        switch self {
        case let .InternalNode(left, right, _, _, _):
            switch path.first! {
            case .Left:
                return left.nodeAtEndOfPath(path: path.suffix(from: path.startIndex + 1))
            case .Right:
                return right.nodeAtEndOfPath(path: path.suffix(from: path.startIndex + 1))
            }
        case _:
            assertionFailure("Path is non-empty, but current node is not an internal node")
        }
        
        return self
    }
    
    func pathToPredecessor(of needle: Point.Position) -> [Direction] {
        switch self {
        case .MinSentinel():
            return []
        case .MaxSentinel():
            return []
        case let .Leaf(position, value, _):
            return []
            
        case let .InternalNode(left, right, (_, rightTreeMin), _, _):
            if gt(needle, rightTreeMin) {
                return [.Right] + right.pathToPredecessor(of: needle)
            }
            else {
                return [.Left] + left.pathToPredecessor(of: needle)
            }
        }
    }
    
    func pathToSuccessor(of needle: Point.Position) -> [Direction] {
        switch self {
        case .MinSentinel():
            return []
        case .MaxSentinel():
            return []
        case let .Leaf(position, value, _):
            return []
            
        case let .InternalNode(left, right, (leftTreeMax, _), _, _):
            if lt(needle, leftTreeMax) {
                return [.Left] + left.pathToSuccessor(of: needle)
            }
            else {
                return [.Right] + right.pathToSuccessor(of: needle)
            }
        }
    }
    
    // MARK: - Helpers
    
    // If either value is nil, then it's the min or max b/c it's the special sentinel value
    // Otherwise, work like a normal min/max function.
    private func minOrNil(_ a: Point.Position?, _ b: Point.Position?) -> Point.Position? {
        if let a = a, let b = b {
            return a < b ? a : b
        }
        else {
            return nil
        }
    }
    private func maxOrNil(_ a: Point.Position?, _ b: Point.Position?) -> Point.Position? {
        if let a = a, let b = b {
            return a > b ? a : b
        }
        else {
            return nil
        }
    }
    
    // Make it easier to deal with our special min/max values of nil
    private func lt(_ a: Point.Position?, _ b: Point.Position?) -> Bool {
        if let a = a {
            if let b = b {
                return a < b
            }
            else {
                // any > nil == false
                return false
            }
        }
        else {
            // nil > any == true
            return true
        }
    }
    private func lte(_ a: Point.Position?, _ b: Point.Position?) -> Bool {
        return lt(a, b) || a == b
    }
    private func gt(_ a: Point.Position?, _ b: Point.Position?) -> Bool {
        if let a = a {
            if let b = b {
                return a > b
            }
            else {
                // any > nil == false
                return false
            }
        }
        else {
            // nil > any == true
            return true
        }
    }
    private func gte(_ a: Point.Position?, _ b: Point.Position?) -> Bool {
        return gt(a, b) || a == b
    }
}
