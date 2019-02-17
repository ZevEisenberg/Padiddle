// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
internal enum L10n {
  /// About Padiddle
  internal static let about = L10n.tr("Localizable", "about")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel")
  /// Clear Drawing
  internal static let clearDrawing = L10n.tr("Localizable", "clearDrawing")
  /// Colors
  internal static let colors = L10n.tr("Localizable", "colors")
  /// Clear the current drawing
  internal static let buttonsClear = L10n.tr("Localizable", "buttons.clear")
  /// Color Settings
  internal static let buttonsColor = L10n.tr("Localizable", "buttons.color")
  /// Help
  internal static let buttonsHelp = L10n.tr("Localizable", "buttons.help")
  /// Start Recording
  internal static let buttonsRecord = L10n.tr("Localizable", "buttons.record")
  /// Share
  internal static let buttonsShare = L10n.tr("Localizable", "buttons.share")
  /// Stop Recording
  internal static let buttonsStop = L10n.tr("Localizable", "buttons.stop")
  /// 3-D
  internal static let colors3D = L10n.tr("Localizable", "colors.3D")
  /// Autumn
  internal static let colorsAutumn = L10n.tr("Localizable", "colors.autumn")
  /// Black Widow
  internal static let colorsBlackWidow = L10n.tr("Localizable", "colors.blackWidow")
  /// Classic
  internal static let colorsClassic = L10n.tr("Localizable", "colors.classic")
  /// Film Noir
  internal static let colorsFilmNoir = L10n.tr("Localizable", "colors.filmNoir")
  /// Merlin
  internal static let colorsMerlin = L10n.tr("Localizable", "colors.merlin")
  /// Monsters
  internal static let colorsMonsters = L10n.tr("Localizable", "colors.monsters")
  /// Pastels
  internal static let colorsPastels = L10n.tr("Localizable", "colors.pastels")
  /// Regolith
  internal static let colorsRegolith = L10n.tr("Localizable", "colors.regolith")
  /// Sepia
  internal static let colorsSepia = L10n.tr("Localizable", "colors.sepia")
  /// Tangerine
  internal static let colorsTangerine = L10n.tr("Localizable", "colors.tangerine")
  /// Watercolor
  internal static let colorsWatercolor = L10n.tr("Localizable", "colors.watercolor")
  /// Spin to Draw
  internal static let tutorialSpinPrompt = L10n.tr("Localizable", "tutorial.spinPrompt")
  /// Start Here
  internal static let tutorialStartHere = L10n.tr("Localizable", "tutorial.startHere")
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
