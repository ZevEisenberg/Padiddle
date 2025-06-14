import Testing

@Suite
struct ArrayTests {
  @Test
  func removeObject() {
    var a1 = [1, 2, 3]
    a1.remove(1)
    #expect(a1 == [2, 3])

    var a2 = [Int]()
    a2.remove(1)
    #expect(a2.isEmpty)

    var a3 = [3, 4, 5]
    let toRemove = 1
    #expect(!a3.contains(toRemove))
    a3.remove(1)
    #expect(a3 == [3, 4, 5])
  }

  @Test
  func interleavingArrays() {
    let long = ["a", "b", "c", "d", "e"]
    let short = ["1", "2", "3", "4"]

    #expect(long.interleaved(with: short) == ["a", "1", "b", "2", "c", "3", "d", "4", "e"])
    #expect(short.interleaved(with: long) == ["a", "1", "b", "2", "c", "3", "d", "4", "e"])

    #expect([1].interleaved(with: [Int]()) == [1])
    #expect([Int]().interleaved(with: [1]) == [1])
  }
}
