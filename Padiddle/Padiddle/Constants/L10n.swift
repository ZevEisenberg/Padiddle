// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
internal enum L10n {
  /// About Padiddle
  internal static let about = L10n.tr("Localizable", "about", fallback: "About Padiddle")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Clear Drawing
  internal static let clearDrawing = L10n.tr("Localizable", "clearDrawing", fallback: "Clear Drawing")
  /// Colors
  internal static let colors = L10n.tr("Localizable", "colors", fallback: "Colors")
  /// Clear the current drawing
  internal static let buttonsClear = L10n.tr("Localizable", "buttons.clear", fallback: "Clear the current drawing")
  /// Color Settings
  internal static let buttonsColor = L10n.tr("Localizable", "buttons.color", fallback: "Color Settings")
  /// Help
  internal static let buttonsHelp = L10n.tr("Localizable", "buttons.help", fallback: "Help")
  /// Start Recording
  internal static let buttonsRecord = L10n.tr("Localizable", "buttons.record", fallback: "Start Recording")
  /// Share
  internal static let buttonsShare = L10n.tr("Localizable", "buttons.share", fallback: "Share")
  /// Stop Recording
  internal static let buttonsStop = L10n.tr("Localizable", "buttons.stop", fallback: "Stop Recording")
  /// 3-D
  internal static let colors3D = L10n.tr("Localizable", "colors.3D", fallback: "3-D")
  /// Autumn
  internal static let colorsAutumn = L10n.tr("Localizable", "colors.autumn", fallback: "Autumn")
  /// Black Widow
  internal static let colorsBlackWidow = L10n.tr("Localizable", "colors.blackWidow", fallback: "Black Widow")
  /// Classic
  internal static let colorsClassic = L10n.tr("Localizable", "colors.classic", fallback: "Classic")
  /// Film Noir
  internal static let colorsFilmNoir = L10n.tr("Localizable", "colors.filmNoir", fallback: "Film Noir")
  /// Merlin
  internal static let colorsMerlin = L10n.tr("Localizable", "colors.merlin", fallback: "Merlin")
  /// Monsters
  internal static let colorsMonsters = L10n.tr("Localizable", "colors.monsters", fallback: "Monsters")
  /// Pastels
  internal static let colorsPastels = L10n.tr("Localizable", "colors.pastels", fallback: "Pastels")
  /// Regolith
  internal static let colorsRegolith = L10n.tr("Localizable", "colors.regolith", fallback: "Regolith")
  /// Sepia
  internal static let colorsSepia = L10n.tr("Localizable", "colors.sepia", fallback: "Sepia")
  /// Tangerine
  internal static let colorsTangerine = L10n.tr("Localizable", "colors.tangerine", fallback: "Tangerine")
  /// Watercolor
  internal static let colorsWatercolor = L10n.tr("Localizable", "colors.watercolor", fallback: "Watercolor")
  /// Spin to Draw
  internal static let tutorialSpinPrompt = L10n.tr("Localizable", "tutorial.spinPrompt", fallback: "Spin to Draw")
  /// Start Here
  internal static let tutorialStartHere = L10n.tr("Localizable", "tutorial.startHere", fallback: "Start Here")
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
