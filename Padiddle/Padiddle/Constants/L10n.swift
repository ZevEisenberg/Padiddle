// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable identifier_name line_length type_body_length
enum L10n {
  /// About Padiddle
  static let about = L10n.tr("Localizable", "about")
  /// Cancel
  static let cancel = L10n.tr("Localizable", "cancel")
  /// Clear Drawing
  static let clearDrawing = L10n.tr("Localizable", "clearDrawing")
  /// Colors
  static let colors = L10n.tr("Localizable", "colors")
  /// Clear the current drawing
  static let buttonsClear = L10n.tr("Localizable", "buttons.clear")
  /// Color Settings
  static let buttonsColor = L10n.tr("Localizable", "buttons.color")
  /// Help
  static let buttonsHelp = L10n.tr("Localizable", "buttons.help")
  /// Start Recording
  static let buttonsRecord = L10n.tr("Localizable", "buttons.record")
  /// Share
  static let buttonsShare = L10n.tr("Localizable", "buttons.share")
  /// Stop Recording
  static let buttonsStop = L10n.tr("Localizable", "buttons.stop")
  /// 3-D
  static let colors3D = L10n.tr("Localizable", "colors.3D")
  /// Autumn
  static let colorsAutumn = L10n.tr("Localizable", "colors.autumn")
  /// Black Widow
  static let colorsBlackWidow = L10n.tr("Localizable", "colors.blackWidow")
  /// Classic
  static let colorsClassic = L10n.tr("Localizable", "colors.classic")
  /// Film Noir
  static let colorsFilmNoir = L10n.tr("Localizable", "colors.filmNoir")
  /// Merlin
  static let colorsMerlin = L10n.tr("Localizable", "colors.merlin")
  /// Monsters
  static let colorsMonsters = L10n.tr("Localizable", "colors.monsters")
  /// Pastels
  static let colorsPastels = L10n.tr("Localizable", "colors.pastels")
  /// Regolith
  static let colorsRegolith = L10n.tr("Localizable", "colors.regolith")
  /// Sepia
  static let colorsSepia = L10n.tr("Localizable", "colors.sepia")
  /// Tangerine
  static let colorsTangerine = L10n.tr("Localizable", "colors.tangerine")
  /// Watercolor
  static let colorsWatercolor = L10n.tr("Localizable", "colors.watercolor")
  /// Spin to Draw
  static let tutorialSpinPrompt = L10n.tr("Localizable", "tutorial.spinPrompt")
  /// Start Here
  static let tutorialStartHere = L10n.tr("Localizable", "tutorial.startHere")
}
// swiftlint:enable identifier_name line_length type_body_length

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
