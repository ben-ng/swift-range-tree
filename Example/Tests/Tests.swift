import UIKit
import XCTest
@testable import RangeTree

let asc = {(a: CGPoint, b:CGPoint) -> Bool in
    if a.x == b.x {
        return a.y < b.y
    }
    else {
        return a.x < b.x
    }
}
let constructorPerformancePoints = 1000
let searchPerformancePoints = 100000
let rangeSize: (UInt32, UInt32) = (1000, 1000)
let searchRangeSize = CGSize(width: 200.0, height: 200.0)

func generateTwoDimensionalPoints(_ count: Int) -> [CGPoint] {
    return (0..<count).map() { _ in CGPoint(x: Double(arc4random_uniform(rangeSize.0)), y: Double(arc4random_uniform(rangeSize.1))) }
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
        XCTAssertEqual(a.debugDescription, "1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0")
        XCTAssertEqual(a.valuesInRange(rangePerDimension: (3.0, 6.0)), [3.0, 4.0, 5.0, 6.0])
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
        XCTAssertEqual(b.debugDescription, "(1.0, 9.0) (2.0, 7.0) (3.0, 10.0) (4.0, 5.0) (5.0, 4.0) (6.0, 8.0) (7.0, 2.0) (8.0, 6.0) (9.0, 1.0) (10.0, 3.0)")
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 2.0), (5.0, 8.0)), [CGPoint(x: 2, y: 7)])
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (1.0, 3.0), (5.0, 8.0)), [CGPoint(x: 2, y: 7)])
        XCTAssertEqual(b.valuesInRange(rangePerDimension: (2.0, 6.0), (2.0, 6.0)).sorted(by: asc), [CGPoint(x: 4, y: 5), CGPoint(x: 5, y: 4)].sorted(by: asc))
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
            _ = values.filter() {
                let x = $0.positionIn(dimension: 0)
                let y = $0.positionIn(dimension: 1)
                return x >= origin.x && x <= origin.x + searchRangeSize.width &&
                    y >= origin.y && y <= origin.y + searchRangeSize.height
            }
        }
    }
    
}
