import Foundation

enum Defaults {
  static var snapshotMode: Bool {
    UserDefaults.standard.bool(forKey: snapshotKey)
  }

  static var colorPickerSelection: Int {
    get {
      if snapshotMode {
        return snapshotPersistedIndex
      } else {
        return (UserDefaults().object(forKey: colorPickerPersistentIndexKey) as? Int) ?? deafultPersistedIndex
      }
    }
    set(newSelection) {
      UserDefaults().set(newSelection, forKey: colorPickerPersistentIndexKey)
    }
  }

  private static let snapshotPersistedIndex = 6
  private static let deafultPersistedIndex = 0

  private static let colorPickerPersistentIndexKey = "ColorPickerIndex"
  private static let snapshotKey = "FASTLANE_SNAPSHOT"
}
