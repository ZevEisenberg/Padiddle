import IdentifiedCollections

public extension ColorGenerator {
  static var toPick: IdentifiedArrayOf<ColorGenerator> {
    [
      classic,
      sepia,
      blackWidow,
      autumn,
      tangerine,
      ddd,
      watercolor,
      monsters,
      pastels,
      merlin,
      regolith,
      filmNoir,
    ]
  }

  static var classic: Self {
    ColorGenerator(
      title: .colorsClassic,
      model: .init(
        space: .hsv,
        components: (
          .thetaIncreasing,
          .manual(1),
          .velocityIn
        )
      )
    )
  }

  static var sepia: Self {
    ColorGenerator(
      title: .colorsSepia,
      model: .init(
        space: .hsv,
        components: (
          .manual(30 / 360),
          .manual(0.2),
          .thetaIncreasingAndDecreasing
        )
      )
    )
  }

  static var blackWidow: Self {
    ColorGenerator(
      title: .colorsBlackWidow,
      model: .init(
        space: .hsv,
        components: (
          .manual(0),
          .manual(1),
          .velocityIn
        )
      )
    )
  }

  static var autumn: Self {
    ColorGenerator(
      title: .colorsAutumn,
      model: .init(
        space: .rgb,
        components: (
          .velocityOut,
          .manual(0.45),
          .manual(0)
        )
      )
    )
  }

  static var tangerine: Self {
    ColorGenerator(
      title: .colorsTangerine,
      model: .init(
        space: .hsv,
        components: (
          .manual(30 / 360),
          .velocityIn,
          .manual(1)
        )
      )
    )
  }

  /// Because `3D` in backticks was causing problems for poor SwiftFormat.
  static var ddd: Self {
    ColorGenerator(
      title: .colors3D,
      model: .init(
        space: .rgb,
        components: (
          .thetaIncreasingAndDecreasing,
          .thetaIncreasing,
          .thetaIncreasing
        )
      )
    )
  }

  static var watercolor: Self {
    ColorGenerator(
      title: .colorsWatercolor,
      model: .init(
        space: .rgb,
        components: (
          .thetaIncreasingAndDecreasing,
          .velocityIn,
          .thetaIncreasing
        )
      )
    )
  }

  static var monsters: Self {
    ColorGenerator(
      title: .colorsMonsters,
      model: .init(
        space: .rgb,
        components: (
          .velocityIn,
          .velocityOut,
          .velocityIn
        )
      )
    )
  }

  static var pastels: Self {
    ColorGenerator(
      title: .colorsPastels,
      model: .init(
        space: .hsv,
        components: (
          .thetaIncreasingAndDecreasing,
          .manual(0.33),
          .velocityOut
        )
      )
    )
  }

  static var merlin: Self {
    ColorGenerator(
      title: .colorsMerlin,
      model: .init(
        space: .hsv,
        components: (
          .velocityIn,
          .velocityOut,
          .thetaIncreasingAndDecreasing
        )
      )
    )
  }

  static var regolith: Self {
    ColorGenerator(
      title: .colorsRegolith,
      model: .init(
        space: .hsv,
        components: (
          .manual(0),
          .manual(0),
          .velocityOut
        )
      )
    )
  }

  static var filmNoir: Self {
    ColorGenerator(
      title: .colorsFilmNoir,
      model: .init(
        space: .hsv,
        components: (
          .manual(0),
          .manual(0),
          .thetaIncreasingAndDecreasing
        )
      )
    )
  }
}
