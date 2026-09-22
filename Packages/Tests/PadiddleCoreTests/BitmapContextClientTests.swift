import CoreGraphics
import Testing

@testable import PadiddleCore

@Suite
struct BitmapContextClientTests {
  /// Growing the bitmap keeps the drawing, at the same size, in the center of the new bitmap.
  @Test
  func growingKeepsTheDrawingCentered() async {
    let client = BitmapContextClient()
    #expect(await client.ensureSideLength(10, screenScale: 1))

    await client.contextOperation { context in
      context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    #expect(await client.ensureSideLength(20, screenScale: 1))
    #expect(await client.contextSideLength == 20)

    // The old 10×10 drawing now spans pixels 5 through 14 on both axes.
    #expect(await client.alpha(x: 4, y: 4) == 0)
    #expect(await client.alpha(x: 5, y: 5) == 255)
    #expect(await client.alpha(x: 14, y: 14) == 255)
    #expect(await client.alpha(x: 15, y: 15) == 0)
    #expect(await client.alpha(x: 5, y: 14) == 255)
    #expect(await client.alpha(x: 14, y: 5) == 255)
  }

  @Test
  func smallerSideLengthIsIgnored() async {
    let client = BitmapContextClient()
    #expect(await client.ensureSideLength(20, screenScale: 1))
    #expect(await client.ensureSideLength(10, screenScale: 1))
    #expect(await client.contextSideLength == 20)
    #expect(await client.contextOperation { $0.width } == 20)
  }

  /// A later scale is ignored, so the old pixels aren't drawn at the wrong physical size.
  @Test
  func firstScaleSticks() async {
    let client = BitmapContextClient()
    #expect(await client.ensureSideLength(10, screenScale: 2))
    #expect(await client.ensureSideLength(20, screenScale: 3))
    #expect(await client.screenScale == 2)
    #expect(await client.contextOperation { $0.width } == 40)
  }
}

private extension BitmapContextClient {
  /// The alpha of the pixel at raw pixel coordinates, with the origin at the top left of the
  /// backing store.
  func alpha(x: Int, y: Int) -> UInt8 {
    contextOperation { context in
      let bytes = context.data!.assumingMemoryBound(to: UInt8.self)
      // Premultiplied-first, big-endian: alpha is the first byte of each pixel.
      return bytes[y * context.bytesPerRow + x * 4]
    }
  }
}
