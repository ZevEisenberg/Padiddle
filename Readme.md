# Padiddle

An iOS app that lets you draw pictures by spinning your device on your finger. Product page is [here](https://zeveisenberg.com/padiddle).

### Project structure

The Xcode project is a thin shell; almost all of the code lives in the `Packages/` Swift package.

```
Padiddle.xcodeproj      Xcode project: app, screenshot UI tests, snapshot test host
Padiddle/               App target — @main entry, Info.plist, app icon, live ImageIO dependency
Packages/               Swift package containing all the real code
  Sources/Utilities/    Leaf target: geometry/math helpers, `with`, EffectBuilder
  Sources/Models/       Color generators, spiral rendering (depends on Utilities)
  Sources/PadiddleCore/ TCA features + SwiftUI views (depends on Models, Utilities, TCA)
  Tests/                UtilitiesTests, ModelsTests, PadiddleCoreTests
SnapshotTestHost/       Trivial host app so ModelsTests can render images on a simulator
Test Plans/             Padiddle (all 3 test targets), PadiddleCore, SnapshotTestHost
Screenshots/            fastlane UI-test screenshot driver + pre-rendered drawings
Scripts/                bootstrap, lint (pinned SwiftFormat/SwiftLint), pre-commit hook
fastlane/               test / screenshots / beta / release lanes
```

Dependency direction is `Utilities` → `Models` → `PadiddleCore` → app target; nothing depends back up.

### Getting started

After cloning, run `Scripts/bootstrap.sh` once. It installs Git LFS (snapshot PNGs and icon assets
are LFS-tracked) and symlinks the pre-commit hook. The app target has a build phase that **fails the
build** if that hook is missing.

### Localization

The main impetus for open-sourcing Padiddle was to solicit help from the community in localizing the app. It currently supports the following localizations:

- [Dutch](https://github.com/ZevEisenberg/Padiddle/tree/master/Padiddle/Padiddle/nl.lproj)
- [English](https://github.com/ZevEisenberg/Padiddle/tree/master/Padiddle/Padiddle/Base.lproj) (Base)
- [French](https://github.com/ZevEisenberg/Padiddle/tree/master/Padiddle/Padiddle/fr.lproj)
- [Italian](https://github.com/ZevEisenberg/Padiddle/tree/master/Padiddle/Padiddle/it.lproj)
- [Chinese (Traditional)](https://github.com/ZevEisenberg/Padiddle/tree/master/Padiddle/Padiddle/zh-Hant.lproj)
- [Chinese (Simplified)](https://github.com/ZevEisenberg/Padiddle/tree/master/Padiddle/Padiddle/zh-Hans.lproj)

If you're interested in contributing to the localization effort, please click on the appropriate locale in the above list and submit a pull request to the appropriate `Localizable.Strings` or `help.html` file.
