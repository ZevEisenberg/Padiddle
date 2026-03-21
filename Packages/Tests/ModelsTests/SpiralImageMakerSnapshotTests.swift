import CoreGraphics.CGBase
import SnapshotTesting
import Testing

@testable import Models

@Suite(.snapshots(record: .failed))
struct SpiralImageMakerSnapshotTests {
  @Test(arguments: ColorGenerator.toPick)
  func spiral(generator: ColorGenerator) {
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
