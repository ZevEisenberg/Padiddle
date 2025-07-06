import Foundation
import struct SwiftUI.Color

/// Holds values representing a coordinate while spinning, and then produces a color from those coordinates on-demand.
public struct ColorGenerator: Hashable, Identifiable, Sendable {
  public var title: LocalizedStringResource
  public var model: Model

  public var id: String {
    title.key
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(title.key)
    hasher.combine(model)
  }

  public func color(
    at coordinate: Coordinate
  ) -> Color {
    Self.color(
      model: model,
      at: coordinate
    )
  }
}

public extension ColorGenerator {
  struct Coordinate {
    public var radius: Double
    public var theta: Double {
      didSet {
        theta = theta.truncatingRemainder(dividingBy: 2 * .pi)
      }
    }

    public var maxRadius: Double

    public init(
      radius: Double = 0,
      theta: Double = 0,
      maxRadius: Double = 0
    ) {
      self.radius = radius
      self.theta = theta
      self.maxRadius = maxRadius
    }
  }
}

public struct Triple<Value> {
  public var a: Value
  public var b: Value
  public var c: Value

  public init(
    _ a: Value,
    _ b: Value,
    _ c: Value
  ) {
    self.a = a
    self.b = b
    self.c = c
  }

  var tuple: (Value, Value, Value) {
    (a, b, c)
  }
}

extension Triple: Equatable where Value: Equatable {}
extension Triple: Hashable where Value: Hashable {}
extension Triple: Sendable where Value: Sendable {}

public extension ColorGenerator {
  enum Space: Sendable {
    case hsv
    case rgb
  }

  struct Model: Hashable, Sendable {
    public var space: Space
    public var components: Triple<ComponentBehavior>

    public init(
      space: Space,
      components: Triple<ComponentBehavior>
    ) {
      self.space = space
      self.components = components
    }

    public init(
      space: Space = .hsv,
      components: (ComponentBehavior, ComponentBehavior, ComponentBehavior)
    ) {
      self.space = space
      self.components = .init(components.0, components.1, components.2)
    }
  }
}

private extension ColorGenerator {
  static func color(
    model: Model,
    at coordinate: Coordinate
  ) -> Color {
    let color: Color
    switch model.space {
    case .hsv:
      let (hBehavior, sBehavior, vBehavior) = model.components.tuple
      let h = componentValue(at: coordinate, behavior: hBehavior)
      let s = componentValue(at: coordinate, behavior: sBehavior)
      let v = componentValue(at: coordinate, behavior: vBehavior)
      color = Color(hue: h, saturation: s, brightness: v)

    case .rgb:
      let (rBehavior, gBehavior, bBehavior) = model.components.tuple
      let r = componentValue(at: coordinate, behavior: rBehavior)
      let g = componentValue(at: coordinate, behavior: gBehavior)
      let b = componentValue(at: coordinate, behavior: bBehavior)
      color = Color(red: r, green: g, blue: b)
    }

    return color
  }

  static func componentValue(
    at coordinate: Coordinate,
    behavior: ComponentBehavior
  ) -> Double {
    let (radius, maxRadius, theta) = (coordinate.radius, coordinate.maxRadius, coordinate.theta)
    let channelValue: Double
    switch behavior {
    case .thetaIncreasing:
      channelValue = theta / (2 * .pi)

    case .thetaIncreasingAndDecreasing:
      let value: Double = if theta > .pi {
        (2 * .pi) - theta
      } else {
        theta
      }
      channelValue = value / .pi

    case .velocityOut:
      assert(maxRadius > 0)
      channelValue = radius / maxRadius

    case .velocityIn:
      assert(maxRadius > 0)
      channelValue = 1 - (radius / maxRadius)

    case .manual(let value):
      channelValue = value
    }

    return channelValue
  }
}
