import XCTest

class ArrayTests: XCTestCase {
  func testRemoveObject() {
    var a1 = [1, 2, 3]
    a1.remove(1)
    XCTAssertEqual(a1, [2, 3])

    var a2 = [Int]()
    a2.remove(1)
    XCTAssertEqual(a2, [])

    var a3 = [3, 4, 5]
    let toRemove = 1
    XCTAssert(!a3.contains(toRemove))
    a3.remove(1)
    XCTAssertEqual(a3, [3, 4, 5])
  }

  func testInterleavingArrays() {
    let long = ["a", "b", "c", "d", "e"]
    let short = ["1", "2", "3", "4"]

    XCTAssertEqual(long.interleave(with: short), ["a", "1", "b", "2", "c", "3", "d", "4", "e"])
    XCTAssertEqual(short.interleave(with: long), ["a", "1", "b", "2", "c", "3", "d", "4", "e"])

    XCTAssertEqual([1].interleave(with: [Int]()), [1])
    XCTAssertEqual([Int]().interleave(with: [1]), [1])
  }
}
