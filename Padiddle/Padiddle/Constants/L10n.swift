// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable file_length
// swiftlint:disable line_length

// swiftlint:disable type_body_length
enum L10n {
  /// About Padiddle
  case about
  /// Cancel
  case cancel
  /// Clear Drawing
  case clearDrawing
  /// Colors
  case colors
  /// Clear the current drawing
  case buttonsClear
  /// Color Settings
  case buttonsColor
  /// Help
  case buttonsHelp
  /// Start Recording
  case buttonsRecord
  /// Share
  case buttonsShare
  /// Stop Recording
  case buttonsStop
  /// 3-D
  case colors3D
  /// Autumn
  case colorsAutumn
  /// Black Widow
  case colorsBlackWidow
  /// Classic
  case colorsClassic
  /// Film Noir
  case colorsFilmNoir
  /// Merlin
  case colorsMerlin
  /// Monsters
  case colorsMonsters
  /// Pastels
  case colorsPastels
  /// Regolith
  case colorsRegolith
  /// Sepia
  case colorsSepia
  /// Tangerine
  case colorsTangerine
  /// Watercolor
  case colorsWatercolor
  /// Spin to Draw
  case tutorialSpinPrompt
  /// Start Here
  case tutorialStartHere
}
// swiftlint:enable type_body_length

extension L10n: CustomStringConvertible {
  var description: String { return self.string }

  var string: String {
    switch self {
      case .about:
        return L10n.tr(key: "about")
      case .cancel:
        return L10n.tr(key: "cancel")
      case .clearDrawing:
        return L10n.tr(key: "clearDrawing")
      case .colors:
        return L10n.tr(key: "colors")
      case .buttonsClear:
        return L10n.tr(key: "buttons.clear")
      case .buttonsColor:
        return L10n.tr(key: "buttons.color")
      case .buttonsHelp:
        return L10n.tr(key: "buttons.help")
      case .buttonsRecord:
        return L10n.tr(key: "buttons.record")
      case .buttonsShare:
        return L10n.tr(key: "buttons.share")
      case .buttonsStop:
        return L10n.tr(key: "buttons.stop")
      case .colors3D:
        return L10n.tr(key: "colors.3D")
      case .colorsAutumn:
        return L10n.tr(key: "colors.autumn")
      case .colorsBlackWidow:
        return L10n.tr(key: "colors.blackWidow")
      case .colorsClassic:
        return L10n.tr(key: "colors.classic")
      case .colorsFilmNoir:
        return L10n.tr(key: "colors.filmNoir")
      case .colorsMerlin:
        return L10n.tr(key: "colors.merlin")
      case .colorsMonsters:
        return L10n.tr(key: "colors.monsters")
      case .colorsPastels:
        return L10n.tr(key: "colors.pastels")
      case .colorsRegolith:
        return L10n.tr(key: "colors.regolith")
      case .colorsSepia:
        return L10n.tr(key: "colors.sepia")
      case .colorsTangerine:
        return L10n.tr(key: "colors.tangerine")
      case .colorsWatercolor:
        return L10n.tr(key: "colors.watercolor")
      case .tutorialSpinPrompt:
        return L10n.tr(key: "tutorial.spinPrompt")
      case .tutorialStartHere:
        return L10n.tr(key: "tutorial.startHere")
    }
  }

  private static func tr(key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

func tr(_ key: L10n) -> String {
  return key.string
}

private final class BundleToken {}
