import Testing
import Utilities

@Suite
struct MathTests {
  @Test
  func closeEnough() {
    #expect(0.00000001.closeEnough(to: 0))
    #expect(0.00000001.closeEnough(to: 0.00000002))
    #expect(!1.closeEnough(to: 2))
    #expect(0.closeEnough(to: 0))
    #expect(1.closeEnough(to: 1))
    #expect((-1).closeEnough(to: -1))
    #expect((-0.00000001).closeEnough(to: 0.00000001))
  }

  @Test
  func zeroIfCloseToZero() {
    #expect(0.zeroIfCloseToZero == 0)
    #expect(1e-10.zeroIfCloseToZero == 0)
    #expect(1e-2.zeroIfCloseToZero != 0)
  }
}
