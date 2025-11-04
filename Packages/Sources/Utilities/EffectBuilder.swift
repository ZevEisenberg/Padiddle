import ComposableArchitecture

public extension Effect {
  static func merge(
    @EffectBuilder<Action> effects: () -> [Self]
  ) -> Self {
    .merge(effects())
  }
}

public extension Effect {
  static func concatenate(
    @EffectBuilder<Action> effects: () -> [Self]
  ) -> Self {
    .concatenate(effects())
  }
}

@resultBuilder
public enum EffectBuilder<Action> {
  public typealias EffectType = Effect<Action>

  public typealias ArrayOfEffects = [EffectType]

  public static func buildExpression(_ effect: EffectType) -> ArrayOfEffects {
    [effect]
  }

  public static func buildExpression(_ effect: EffectType?) -> ArrayOfEffects {
    effect.map { [$0] } ?? []
  }

  public static func buildBlock(_ effects: ArrayOfEffects...) -> ArrayOfEffects {
    effects.flatMap(\.self)
  }

  public static func buildExpression(_ effects: [EffectType]) -> ArrayOfEffects {
    effects
  }

  public static func buildOptional(_ effects: ArrayOfEffects?) -> ArrayOfEffects {
    effects ?? []
  }

  public static func buildBlock(_ effects: ArrayOfEffects) -> ArrayOfEffects {
    effects
  }

  public static func buildEither(first effects: ArrayOfEffects) -> ArrayOfEffects {
    effects
  }

  public static func buildEither(second effects: ArrayOfEffects) -> ArrayOfEffects {
    effects
  }

  public static func buildArray(_ effects: [ArrayOfEffects]) -> ArrayOfEffects {
    effects.flatMap(\.self)
  }
}
