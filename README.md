# RangeTree

[![CI Status](http://img.shields.io/travis/ben-ng/swift-range-tree.svg?style=flat)](https://travis-ci.org/ben-ng/swift-range-tree)
[![Version](https://img.shields.io/cocoapods/v/RangeTree.svg?style=flat)](http://cocoapods.org/pods/RangeTree)
[![License](https://img.shields.io/cocoapods/l/RangeTree.svg?style=flat)](http://cocoapods.org/pods/RangeTree)
[![Platform](https://img.shields.io/cocoapods/p/RangeTree.svg?style=flat)](http://cocoapods.org/pods/RangeTree)

A range tree allows you to perform orthorgonal range searches in logarithmic time. i.e. If you had a bunch of points in two-dimensional space, you can figure out what points have an x coordinate between a and b, and a y coordinate between c and d.

This module implements an n-dimensional range tree -- you define how many dimensions you need. Note that you will see a performance penalty if your dataset is too small. See the section on [performance](#performance) to gauge if your dataset is large enough to benefit from this data structure.

## Usage

1. Implement the `RangeTreePoint` protocol (it's already implemented on `Int`, `Double`, and `CGPoint` for you as part of this module)

	```swift
	public protocol RangeTreePoint {
	    associatedtype Position: Comparable
	    static var dimensions: Int { get}
	    func positionIn(dimension: Int) -> Position
	}

	// Sample implementation
	extension CGPoint: RangeTreePoint {
	    public typealias Position = CGFloat
	    public static var dimensions = 2
	    public func positionIn(dimension: Int) -> Position {
	        return dimension == 0 ? self.x : self.y
	    }
	}
	```
2. Construct a RangeTree

	```swift
	let a = RangeTree<Double>(values: [8, 1, 10, 4, 2, 7, 5, 3, 9, 6])
	```
3. Query for a range

	```swift
	a.valuesInRange(rangePerDimension: (3.0, 6.0)) // => [3.0, 4.0, 5.0, 6.0]
	```
4. Modify the RangeTree

	```swift
	a.insert(4.5)
	a.valuesInRange(rangePerDimension: (3.0, 6.0)) // => [3.0, 4.0, 4.5, 5.0, 6.0]
	```

## Performance

Tested on my quad-core 2.8 GHz i7 Retina MacBook Pro:

 * Constructing a tree
 	* 1000 points: 0.133s
 	* 10000 points: 1.104s
 	* 100000 points: 8.420s
 * Querying a tree
 	* 1000 points: 0.001s (naive `Array.filter`: 0.000s)
 	* 10000 points: 0.002s (naive `Array.filter`: 0.004s)
 	* 100000 points: 0.008s (naive `Array.filter`: 0.029s)

## Example & Tests

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

RangeTree is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RangeTree"
```

## Author

Ben Ng, me@benng.me

## License

RangeTree is available under the MIT license. See the LICENSE file for more info.
