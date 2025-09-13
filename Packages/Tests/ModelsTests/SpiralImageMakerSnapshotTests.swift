import TestHelpers
import XCTest

@testable import Models

final class SpiralImageMakerSnapshotTests: SnapshotTestCase {
  func testSpiral() {
    for generator in ColorGenerator.toPick {
      assertSnapshot(
        of: SpiralImageMaker.image(
          spiralModel: SpiralModel(
            colorGenerator: generator,
            size: CGSize(
              width: 400,
              height: 400
            ),
            startRadius: 0,
            spacePerLoop: 7,
            thetaRange: 0...(4 * 2 * .pi),
            thetaStep: .pi / 64,
            lineWidth: 30
          ),
          scale: 1
        ),
        as: .image(scale: 1),
        named: generator.title.key
      )
    }
  }
}
