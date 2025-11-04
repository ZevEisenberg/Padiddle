@_exported import SnapshotTesting
import XCTest

open class SnapshotTestCase: XCTestCase {
  override open func invokeTest() {
    withSnapshotTesting(
      record: .failed,
      diffTool: .ksdiff
    ) {
      super.invokeTest()
    }
  }
}
