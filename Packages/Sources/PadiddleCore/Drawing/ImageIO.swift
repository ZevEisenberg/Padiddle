import CoreGraphics
import Dependencies
import DependenciesMacros
import Foundation
import UIKit

@DependencyClient
public struct ImageIO: TestDependencyKey, Sendable {
  public var fetchImage: @Sendable (_ sideLengthPixels: Int) -> CGImage?
}

public extension ImageIO {
  static var testValue: Self {
    Self(fetchImage: { _ in nil })
  }
}

extension DependencyValues {
  var imageIO: ImageIO {
    get { self[ImageIO.self] }
    set { self[ImageIO.self] = newValue }
  }
}
