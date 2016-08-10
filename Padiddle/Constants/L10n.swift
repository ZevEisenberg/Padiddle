// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

enum L10n {
  /// About Padiddle
  case About
  /// Cancel
  case Cancel
  /// Clear Drawing
  case ClearDrawing
  /// Colors
  case Colors
  /// Autumn
  case ColorsAutumn
  /// Black Widow
  case ColorsBlackWidow
  /// Classic
  case ColorsClassic
  /// 3-D
  case Colors3D
  /// Film Noir
  case ColorsFilmNoir
  /// Merlin
  case ColorsMerlin
  /// Monsters
  case ColorsMonsters
  /// Pastels
  case ColorsPastels
  /// Regolith
  case ColorsRegolith
  /// Sepia
  case ColorsSepia
  /// Tangerine
  case ColorsTangerine
  /// Watercolor
  case ColorsWatercolor
}

extension L10n: CustomStringConvertible {
  var description: String { return self.string }

  var string: String {
    switch self {
      case .About:
        return L10n.tr(key: "about")
      case .Cancel:
        return L10n.tr(key: "cancel")
      case .ClearDrawing:
        return L10n.tr(key: "clearDrawing")
      case .Colors:
        return L10n.tr(key: "colors")
      case .ColorsAutumn:
        return L10n.tr(key: "colors.autumn")
      case .ColorsBlackWidow:
        return L10n.tr(key: "colors.blackWidow")
      case .ColorsClassic:
        return L10n.tr(key: "colors.classic")
      case .Colors3D:
        return L10n.tr(key: "colors.3D")
      case .ColorsFilmNoir:
        return L10n.tr(key: "colors.filmNoir")
      case .ColorsMerlin:
        return L10n.tr(key: "colors.merlin")
      case .ColorsMonsters:
        return L10n.tr(key: "colors.monsters")
      case .ColorsPastels:
        return L10n.tr(key: "colors.pastels")
      case .ColorsRegolith:
        return L10n.tr(key: "colors.regolith")
      case .ColorsSepia:
        return L10n.tr(key: "colors.sepia")
      case .ColorsTangerine:
        return L10n.tr(key: "colors.tangerine")
      case .ColorsWatercolor:
        return L10n.tr(key: "colors.watercolor")
    }
  }

  private static func tr(key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, locale: NSLocale.current, arguments: args)
  }
}

func tr(key: L10n) -> String {
  return key.string
}
