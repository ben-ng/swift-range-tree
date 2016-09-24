import UIKit
import XCTest
import RangeTree

let asc = {(a: CGPoint, b:CGPoint) -> Bool in
    if a.x == b.x {
        return a.y < b.y
    }
    else {
        return a.x < b.x
    }
}
let constructorPerformancePoints = 1000
let searchPerformancePoints = 10000

// This figures out the right range so that there's approximately one value in every four units of space
let targetResultsPerQuery = 10
let searchRangeWidth = UInt32(sqrt(Double(targetResultsPerQuery)))
let rangeWidth = UInt32(sqrt(Double(searchPerformancePoints)))
let searchRangeOriginMax = rangeWidth - searchRangeWidth

func generateTwoDimensionalPoints(_ count: Int) -> [CGPoint] {
    return (0..<count).map() { _ in CGPoint(x: Double(arc4random_uniform(rangeWidth)), y: Double(arc4random_uniform(rangeWidth))) }
}

func createFilter(searchRangeOrigin origin: CGPoint) -> ((CGPoint) -> Bool) {
    return { (e: CGPoint) -> Bool in
        let x = e.positionIn(dimension: 0)
        let y = e.positionIn(dimension: 1)
        return x >= origin.x && x <= origin.x + CGFloat(searchRangeWidth) &&
            y >= origin.y && y <= origin.y + CGFloat(searchRangeWidth)
    }
}

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        assert(searchRangeWidth <= rangeWidth, "The search range cannot be larger than the range")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test1DRangeTree() {
        let a = RangeTree<Double>(values: [8, 1, 10, 4, 2, 7, 5, 3, 9, 6])
        XCTAssertEqual(a.description, "1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0")
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 4.0, 5.0, 6.0])
        a.insert(4.5)
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 4.0, 4.5, 5.0, 6.0])
        a.remove(5.0)
        a.remove(3.0)
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [4.0, 4.5, 6.0])
    }
    
    func test1DRangeTreeWithDuplicates() {
        let a = RangeTree<Double>(values: [8, 3, 1, 3, 4, 6])
        a.insert(3)
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 3.0, 3.0, 4.0, 6.0])
    }
    
    func test2DRangeTree() {
        let twoDimFixtures = [
            CGPoint(x: 8, y: 6),
            CGPoint(x: 1, y: 9),
            CGPoint(x: 10, y: 3),
            CGPoint(x: 4, y: 5),
            CGPoint(x: 2, y: 7),
            CGPoint(x: 7, y: 2),
            CGPoint(x: 5, y: 4),
            CGPoint(x: 3, y: 10),
            CGPoint(x: 9, y: 1),
            CGPoint(x: 6, y: 8)
        ]
        let b = RangeTree<CGPoint>(values: twoDimFixtures)
        XCTAssertEqual(b.description, "(1.0, 9.0) (2.0, 7.0) (3.0, 10.0) (4.0, 5.0) (5.0, 4.0) (6.0, 8.0) (7.0, 2.0) (8.0, 6.0) (9.0, 1.0) (10.0, 3.0)")
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 2.0), (5.0, 8.0)), [CGPoint(x: 2, y: 7)])
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 3.0), (5.0, 8.0)), [CGPoint(x: 2, y: 7)])
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (2.0, 6.0), (2.0, 6.0)).sorted(by: asc), [CGPoint(x: 4, y: 5), CGPoint(x: 5, y: 4)].sorted(by: asc))
        
        b.insert(CGPoint(x:2.2, y: 5.3))
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 3.0), (5.0, 8.0)).sorted(by: asc), [CGPoint(x: 2, y: 7), CGPoint(x: 2.2, y: 5.3)].sorted(by: asc))
        
        // Add a point that's a duplicate in one dimension but not the other
        b.insert(CGPoint(x: 2.2, y: 5.1))
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 3.0), (5.0, 8.0)).sorted(by: asc), [CGPoint(x: 2, y: 7), CGPoint(x: 2.2, y: 5.1), CGPoint(x: 2.2, y: 5.3)].sorted(by: asc))
        
        b.remove(CGPoint(x: 2, y: 7))
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 3.0), (5.0, 8.0)).sorted(by: asc), [CGPoint(x: 2.2, y: 5.1), CGPoint(x: 2.2, y: 5.3)].sorted(by: asc))
    }
    
    func test2DConstructorPerformance() {
        self.measure() {
            let values = generateTwoDimensionalPoints(constructorPerformancePoints)
            _ = RangeTree<CGPoint>(values: values)
        }
    }
    
    func test2DSearchPerformance() {
        let values = generateTwoDimensionalPoints(searchPerformancePoints)
        let a = RangeTree<CGPoint>(values: values)
        self.measure() {
            let origin = CGPoint(x: CGFloat(arc4random_uniform(searchRangeOriginMax)), y: CGFloat(arc4random_uniform(searchRangeOriginMax)))
            _ = a.valuesInRange(rangePerDimension: (origin.x, origin.x + CGFloat(searchRangeWidth)), (origin.y, origin.y + CGFloat(searchRangeWidth)))
        }
    }
    
    func test2DNaiveSearchPerformance() {
        let values = generateTwoDimensionalPoints(searchPerformancePoints)
        self.measure() {
            let origin = CGPoint(x: CGFloat(arc4random_uniform(searchRangeOriginMax)), y: CGFloat(arc4random_uniform(searchRangeOriginMax)))
            _ = values.filter(createFilter(searchRangeOrigin: origin))
        }
    }
    
//    This takes a while to run, and it's non-deterministic, so
//    I'm going to leave it commented out. It's been useful for
//    catching edge-casey bugs.
//    
//    func testFuzz() {
//        for _ in 0..<100 {
//            let values = generateTwoDimensionalPoints(searchPerformancePoints)
//            let a = RangeTree<CGPoint>(values: values)
//            let origin = CGPoint(x: CGFloat(arc4random_uniform(searchRangeOriginMax)), y: CGFloat(arc4random_uniform(searchRangeOriginMax)))
//            let actual = a.valuesInRange(rangePerDimension: (origin.x, origin.x + CGFloat(searchRangeWidth)), (origin.y, origin.y + CGFloat(searchRangeWidth)))
//            let expected = values.filter(createFilter(searchRangeOrigin: origin))
//            XCTAssertEqual(actual.sorted(by: asc), expected.sorted(by: asc))
//        }
//    }
    
}
