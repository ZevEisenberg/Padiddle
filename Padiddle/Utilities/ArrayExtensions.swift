extension Array where Element: Equatable {
  // Remove first collection element that is equal to the given `object`:
  mutating func remove(_ object: Element) {
    if let index = firstIndex(of: object) {
      remove(at: index)
    }
  }
}

extension Array {
  func interleaved(with otherArray: [Element]) -> [Element] {
    let selfCount = count
    let otherCount = otherArray.count
    let selfIsBigger = selfCount > otherCount
    let largerArray = selfIsBigger ? self : otherArray
    let smallerArray = selfIsBigger ? otherArray : self

    assert(largerArray.count == smallerArray.count + 1, "Arrays must differ in count by exactly 1, but they have counts \(largerArray.count) and \(smallerArray.count)")

    var newArray = [Element]()
    for (index, smallArrayElement) in smallerArray.enumerated() {
      let largeArrayElement = largerArray[index]
      newArray.append(largeArrayElement)
      newArray.append(smallArrayElement)
    }

    guard let largeLast = largerArray.last else {
      fatalError("We have already established that largerArray is 1 larger than smallerArray, so it must have at least one item")
    }
    newArray.append(largeLast)

    return newArray
  }
}
