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
let rangeSize: (UInt32, UInt32) = (1000, 1000)
let searchRangeSize = CGSize(width: 200.0, height: 200.0)

func generateTwoDimensionalPoints(_ count: Int) -> [CGPoint] {
    return (0..<count).map() { _ in CGPoint(x: Double(arc4random_uniform(rangeSize.0)), y: Double(arc4random_uniform(rangeSize.1))) }
}

func createFilter(searchRangeOrigin origin: CGPoint) -> ((CGPoint) -> Bool) {
    return { (e: CGPoint) -> Bool in
        let x = e.positionIn(dimension: 0)
        let y = e.positionIn(dimension: 1)
        return x >= origin.x && x <= origin.x + searchRangeSize.width &&
            y >= origin.y && y <= origin.y + searchRangeSize.height
    }
}

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOneDimensionalRangeTree() {
        let a = RangeTree<Double>(values: [8, 1, 10, 4, 2, 7, 5, 3, 9, 6])
        XCTAssertEqual(a.description, "1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0")
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 4.0, 5.0, 6.0])
        a.insert(4.5)
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 4.0, 4.5, 5.0, 6.0])
    }
    
    func testOneDimensionalRangeTreeWithDuplicates() {
        let a = RangeTree<Double>(values: [8, 3, 1, 3, 4, 6])
        a.insert(3)
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 3.0, 3.0, 4.0, 6.0])
    }
    
    func testTwoDimensionalRangeTree() {
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
    }
    
    func testTwoDimensionalRangeTreeConstructorPerformance() {
        self.measure() {
            let values = generateTwoDimensionalPoints(constructorPerformancePoints)
            _ = RangeTree<CGPoint>(values: values)
        }
    }
    
    func testTwoDimensionalRangeTreeSearchPerformance() {
        let values = generateTwoDimensionalPoints(searchPerformancePoints)
        let a = RangeTree<CGPoint>(values: values)
        self.measure() {
            let origin = CGPoint(x: CGFloat(arc4random_uniform(750)), y: CGFloat(arc4random_uniform(750)))
            _ = a.valuesInRange(rangePerDimension: (origin.x, origin.x + searchRangeSize.width), (origin.y, origin.y + searchRangeSize.height))
        }
    }
    
    func testTwoDimensionalNaiveSearchPerformance() {
        let values = generateTwoDimensionalPoints(searchPerformancePoints)
        self.measure() {
            let origin = CGPoint(x: CGFloat(arc4random_uniform(750)), y: CGFloat(arc4random_uniform(750)))
            _ = values.filter(createFilter(searchRangeOrigin: origin))
        }
    }
    
//    This takes a while to run, and it's non-deterministic, so
//    I'm going to leave it commented out. It's been useful for
//    catching edge-casey bugs.
//    
//    func testTwoDimensionalRangeTreeSearchFuzz() {
//        for _ in 0..<100 {
//            let values = generateTwoDimensionalPoints(searchPerformancePoints)
//            let a = RangeTree<CGPoint>(values: values)
//            let origin = CGPoint(x: CGFloat(arc4random_uniform(750)), y: CGFloat(arc4random_uniform(750)))
//            let actual = a.valuesInRange(rangePerDimension: (origin.x, origin.x + searchRangeSize.width), (origin.y, origin.y + searchRangeSize.height))
//            let expected = values.filter(createFilter(searchRangeOrigin: origin))
//            XCTAssertEqual(actual.sorted(by: asc), expected.sorted(by: asc))
//        }
//    }
    
}
