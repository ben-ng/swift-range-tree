//
//  RangeTree.swift
//  Pods
//
//  Created by Benjamin Ng on 9/18/16.
//
//

import Foundation

public class RangeTree<Point: RangeTreePoint>: CustomDebugStringConvertible, CustomStringConvertible {
    private var rootNode: RangeTreeNode<Point>
    public var description: String {
        return rootNode.description
    }
    public var debugDescription: String {
        return rootNode.debugDescription
    }
    
    required public init(values: [Point]) {
        rootNode = RangeTreeNode<Point>(values: values, dimension: 0)
    }
    
    public func insert(_ newPoint: Point) {
        rootNode = rootNode.insert(value: newPoint, dimension: 0)
    }
    
    public func valuesInRange(rangePerDimension: (Point.Position, Point.Position)...) -> [Point] {
        assert(rangePerDimension.count == Point.dimensions, "The number of ranges must match the number of dimensions")
        
        return rootNode.valuesIn(rangePerDimension: rangePerDimension.suffix(from: rangePerDimension.startIndex))
    }
}

private enum Direction {
    case Left
    case Right
}

private struct Bucket<Point: RangeTreePoint> {
    let position: Point.Position
    var values: [Point]
    var rangeInSortedOriginalValues: Range<Int>
    
    init(position pos: Point.Position, initialValue: Point, indexOfFirstValueInSortedValues firstValIndex: Int) {
        position = pos
        rangeInSortedOriginalValues = firstValIndex..<firstValIndex+1
        values = [initialValue]
    }
}

private struct PreprocessedDimensionData<Point: RangeTreePoint> {
    let buckets: ArraySlice<Bucket<Point>>
    let sortedOriginalValues: ArraySlice<Point>
    // Gets the values in the buckets in the current slice
    var values: ArraySlice<Point> {
        if buckets.isEmpty {
            return []
        }
        else {
            let lowerBound = buckets.first!.rangeInSortedOriginalValues.lowerBound
            let upperBound = buckets.last!.rangeInSortedOriginalValues.upperBound
            return sortedOriginalValues[lowerBound..<upperBound]
        }
    }
    var midIndex: Int {
        return buckets.startIndex + buckets.count / 2
    }
    var leftSubtreeData: PreprocessedDimensionData<Point> {
        return PreprocessedDimensionData<Point>(buckets: buckets[buckets.startIndex..<midIndex], sortedOriginalValues: sortedOriginalValues)
    }
    var rightSubtreeData: PreprocessedDimensionData<Point> {
        return PreprocessedDimensionData<Point>(buckets: buckets.suffix(from: midIndex), sortedOriginalValues: sortedOriginalValues)
    }
    var max: Point.Position? {
        return buckets.last?.position
    }
    var min: Point.Position? {
        return buckets.first?.position
    }
    var leftSubtreeMax: Point.Position? {
        return leftSubtreeData.max
    }
    var rightSubtreeMin: Point.Position? {
        return rightSubtreeData.min
    }
    
    init(dimension onDimension: Int, values: ArraySlice<Point>) {
        let sortedValues = values.sorted {$0.positionIn(dimension: onDimension) < $1.positionIn(dimension: onDimension)}
        var lastValueBucket: Bucket<Point>?
        var processed = [Bucket<Point>]()
        for (sortedIndex, value) in sortedValues.enumerated() {
            let pos = value.positionIn(dimension: onDimension)
            let shouldAppendToLastBucket = lastValueBucket?.position == pos
            
            if shouldAppendToLastBucket {
                lastValueBucket!.values.append(value)
            }
            else {
                if var lastValueBucket = lastValueBucket {
                    lastValueBucket.rangeInSortedOriginalValues = lastValueBucket.rangeInSortedOriginalValues.lowerBound..<sortedIndex
                    processed.append(lastValueBucket)
                }
                lastValueBucket = Bucket<Point>(position: pos, initialValue: value, indexOfFirstValueInSortedValues: sortedIndex)
            }
        }
        if var lastValueBucket = lastValueBucket {
            lastValueBucket.rangeInSortedOriginalValues = lastValueBucket.rangeInSortedOriginalValues.lowerBound..<sortedValues.count
            processed.append(lastValueBucket)
        }
        buckets = ArraySlice<Bucket<Point>>(processed)
        sortedOriginalValues = ArraySlice<Point>(sortedValues)
    }
    
    init(buckets b: ArraySlice<Bucket<Point>>, sortedOriginalValues v: ArraySlice<Point>) {
        buckets = b
        sortedOriginalValues = v
    }
}

private enum RangeTreeNode<Point: RangeTreePoint>: CustomDebugStringConvertible, CustomStringConvertible {
    case MinSentinel()
    case MaxSentinel()
    indirect case Leaf(position: Point.Position, values: [Point], nextDimension: RangeTreeNode<Point>?)
    indirect case InternalNode(left: RangeTreeNode<Point>, right: RangeTreeNode<Point>, limits: (Point.Position?, Point.Position?), weight: Int, nextDimension: RangeTreeNode<Point>?)
    
    var values: [Point] {
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
    
    var weight: Int {
        switch self {
        case .MinSentinel():
            return 1
        case .MaxSentinel():
            return 1
        case .Leaf:
            return 1
        case let .InternalNode(left, right, _, _, _):
            return left.weight + right.weight
        }
    }
    
    var description: String {
        return values.map({"\($0)"}).joined(separator: " ")
    }
    
    // This isn't very robust, but it's good enough
    var debugDescription: String {
        switch self {
        case .MinSentinel():
            return "\"MINSENTINEL\""
        case .MaxSentinel():
            return "\"MAXSENTINEL\""
        case let .Leaf(pos, values, _):
            return "\"\(pos): " + values.map({"\($0)"}).joined(separator: ", ") + "\""
        case let .InternalNode(left, right, (lMax, rMin), _, _):
            return "{leftMax: \"\(lMax)\", rightMin: \"\(rMin)\", left: \(left.debugDescription), right: \(right.debugDescription)}"
        }
    }
    
    init(values: [Point], dimension onDimension: Int=0) {
        self.init(values: ArraySlice<Point>(values), dimension: onDimension)
    }
    
    init(values: ArraySlice<Point>, dimension onDimension: Int=0) {
        self.init(dimension: onDimension, preprocessedDataForDimension: PreprocessedDimensionData(dimension: onDimension, values: values), insertSentinels: true)
    }
    
    private init(dimension onDimension: Int, preprocessedDataForDimension _preprocessedDataForDimension: PreprocessedDimensionData<Point>?=nil, insertSentinels: Bool) {
        // If a second argument was not provided, assume an empty node is being created, and generate empty preprocessed data
        let curData = _preprocessedDataForDimension ?? PreprocessedDimensionData<Point>(dimension: onDimension, values: [])
        let hasNextDimension = onDimension < Point.dimensions - 1
        let buckets = curData.buckets
        var rootNode: RangeTreeNode<Point>
        
        if buckets.count == 0 {
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(dimension: onDimension + 1, preprocessedDataForDimension: nil, insertSentinels: true) :
                nil
            if insertSentinels {
                self = .InternalNode(left: .MinSentinel(), right: .MaxSentinel(), limits: (nil, nil), weight: 2, nextDimension: nextDimension)
                // Special case! Don't do the insertSentinel at the end or you'll double up on them
                return
            }
            else {
                assertionFailure("Invalid recursive call to init on an empty value set")
                self = .MinSentinel()
                return
            }
        }
        else if buckets.count == 1 {
            let bucket = buckets.first!
            let leafValues = bucket.values
            
            // Note that the same next dimension tree can be used for the internal node as well as the leaf node; there's
            // only one value in both cases, and it's the same value.
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(values: leafValues, dimension: onDimension + 1) :
                nil
            rootNode = .Leaf(position: bucket.position, values: leafValues, nextDimension: nextDimension)
        }
        else {
            let leftTree = RangeTreeNode<Point>.init(dimension: onDimension, preprocessedDataForDimension: curData.leftSubtreeData, insertSentinels: false)
            let rightTree = RangeTreeNode<Point>.init(dimension: onDimension, preprocessedDataForDimension: curData.rightSubtreeData, insertSentinels: false)
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(values: curData.values, dimension: onDimension + 1) :
                nil
            rootNode = .InternalNode(left: leftTree, right: rightTree, limits: (curData.leftSubtreeMax, curData.rightSubtreeMin), weight: leftTree.weight + rightTree.weight, nextDimension: nextDimension)
        }
        
        if insertSentinels && curData.buckets.count > 0 {
            let newRootNode = rootNode.insertMinSentinel(min: curData.buckets.first!.position)
                            .insertMaxSentinel(max: curData.buckets.last!.position)
            self = newRootNode
        }
        else {
            self = rootNode
        }
    }
    
    private func insertMinSentinel(min: Point.Position) -> RangeTreeNode {
        switch self {
        case .MinSentinel:
            assertionFailure("Cannot insert sentinels when they already exist")
            return self
        case .MaxSentinel:
            return self
        case let .Leaf(pos, _, nextDimension):
            if pos == min {
                return .InternalNode(left: .MinSentinel(), right: self, limits: (nil, pos), weight: 2, nextDimension: nextDimension)
            }
            else {
                return self
            }
        case let .InternalNode(left, right, limits, weight, nextDimension):
            return .InternalNode(left: left.insertMinSentinel(min: min), right: right, limits: limits, weight: weight + 2, nextDimension: nextDimension)
        }
    }
    
    private func insertMaxSentinel(max: Point.Position) -> RangeTreeNode {
        switch self {
        case .MinSentinel:
            return self
        case .MaxSentinel:
            assertionFailure("Cannot insert sentinels when they already exist")
            return self
        case let .Leaf(pos, _, nextDimension):
            if pos == max {
                return RangeTreeNode<Point>.InternalNode(left: self, right: .MaxSentinel(), limits: (pos, nil), weight: 2, nextDimension: nextDimension)
            }
            else {
                return self
            }
        case let .InternalNode(left, right, limits, weight, nextDimension):
            return .InternalNode(left: left, right: right.insertMaxSentinel(max: max), limits: limits, weight: weight + 2, nextDimension: nextDimension)
        }
    }
    
    func insert(value newValue: Point, dimension onDimension: Int) -> RangeTreeNode {
        let hasNextDimension = onDimension < Point.dimensions - 1
        let newPosition = newValue.positionIn(dimension: onDimension)
        
        switch self {
        case .MinSentinel():
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(values: [newValue], dimension: onDimension + 1) :
            nil
            let right: RangeTreeNode<Point> = .Leaf(position: newPosition, values: [newValue], nextDimension: nextDimension)
            return .InternalNode(left: .MinSentinel(), right: right, limits: (nil, newPosition), weight: 2, nextDimension: nextDimension)
            
        case .MaxSentinel():
            let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                RangeTreeNode<Point>(values: [newValue], dimension: onDimension + 1) :
            nil
            let left: RangeTreeNode<Point> = .Leaf(position: newPosition, values: [newValue], nextDimension: nextDimension)
            return .InternalNode(left: left, right: .MaxSentinel(), limits: (newPosition, nil), weight: 2, nextDimension: nextDimension)
            
        case let .Leaf(oldPosition, oldValues, oldNextDimension):
            // If a leaf for this position already exists, append the value to the leaf
            if newPosition == oldPosition {
                let nextDimension: RangeTreeNode<Point>? = hasNextDimension ?
                    RangeTreeNode<Point>(values: oldValues + [newValue], dimension: onDimension + 1) :
                    nil
                return .Leaf(position: oldPosition, values: oldValues + [newValue], nextDimension: nextDimension)
            }
            // Otherwise, split the existing leaf up by turning it into an internal node
            else {
                let nextLeafDimension: RangeTreeNode<Point>? = hasNextDimension ?
                    RangeTreeNode<Point>(values: [newValue], dimension: onDimension + 1) :
                    nil
                let nextInternalNodeDimension: RangeTreeNode<Point>? = hasNextDimension ?
                    RangeTreeNode<Point>(values: oldValues + [newValue], dimension: onDimension + 1) :
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
                RangeTreeNode<Point>(values: left.values + right.values + [newValue], dimension: onDimension + 1) :
                nil
            
            if lte(newPosition, leftTreeMax) {
                return .InternalNode(left: left.insert(value: newValue, dimension: onDimension), right: right, limits: (leftTreeMax, rightTreeMin), weight: weight + 1, nextDimension: nextDimension)
            }
            else if gte(newPosition, rightTreeMin) {
                return .InternalNode(left: left, right: right.insert(value: newValue, dimension: onDimension), limits: (leftTreeMax, rightTreeMin), weight: weight + 1, nextDimension: nextDimension)
            }
            // If the new position sits between the max of the left tree and the min of the right tree, (arbitrarily) insert
            // it on the left subtree, taking care to update the max of the left tree to the new position
            else {
                return .InternalNode(left: left.insert(value: newValue, dimension: onDimension), right: right, limits: (newPosition, rightTreeMin), weight: weight + 1, nextDimension: nextDimension)
            }
        }
    }
    
    func valuesIn(rangePerDimension: ArraySlice<(Point.Position, Point.Position)>) -> [Point] {
        assert(rangePerDimension.count > 0)
        
        let (min, max) = rangePerDimension.first!
        
        if case .MinSentinel = self {
            return []
        }
        if case .MaxSentinel = self {
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
            if case .Leaf = commonAncestorLeft {
                answerNodes.append(commonAncestorLeft)
            }
            if case .Leaf = commonAncestorRight {
                answerNodes.append(commonAncestorRight)
            }
//            print("-----------")
//            print("Dimension: \(Point.dimensions - rangePerDimension.count)")
//            print("Include: \(min)-\(max)")
//            print("Structure: \(debugDescription)")
//            print("Answer Nodes: \(answerNodes)")
//            print("-----------")
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
            case .Leaf:
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
            case .Leaf:
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
        case .MinSentinel:
            return []
        case .MaxSentinel:
            return []
        case .Leaf:
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
        case .MinSentinel:
            return []
        case .MaxSentinel:
            return []
        case .Leaf:
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
