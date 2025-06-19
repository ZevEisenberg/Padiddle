import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  var drawingViewController: DrawingViewController?
  var toolbarViewController: ToolbarViewController?
  var rootViewModel: RootViewModel!

  // Private Properties

  private let spinManager = SpinManager()

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else {
      Log.error("Could not convert to UIWindowScene: \(scene)")
      return
    }

    toolbarViewController = ToolbarViewController(spinManager: spinManager, maximumFramesPerSecond: windowScene.screen.maximumFramesPerSecond)

    let drawingViewModel = DrawingViewModel(
      maxRadius: windowScene.screen.shortestSide,
      contextSize: CGSize(
        width: windowScene.screen.longestSide,
        height: windowScene.screen.longestSide
      ),
      screenScale: windowScene.screen.scale,
      spinManager: spinManager
    )

    rootViewModel = RootViewModel(rootColorManagerDelegate: drawingViewModel)

    let toolbarViewModel = ToolbarViewModel(rootViewModel: rootViewModel, toolbarDelegate: toolbarViewController!, colorDelegate: rootViewModel)

    toolbarViewController?.viewModel = toolbarViewModel

    rootViewModel.rootColorManagerDelegate = drawingViewModel

    drawingViewController = DrawingViewController(viewModel: drawingViewModel, screenLongestSideLength: windowScene.screen.longestSide)

    rootViewModel.drawingViewController = drawingViewController

    rootViewModel.addRecordingDelegate(toolbarViewModel)
    rootViewModel.addRecordingDelegate(drawingViewModel)

    let rootViewController = RootViewController(viewModel: rootViewModel, pinnedViewController: drawingViewController!, rotatingViewController: toolbarViewController!)
    rootViewController.view.accessibilityIdentifier = "root view"

    window = UIWindow(windowScene: windowScene)
    window!.rootViewController = rootViewController
    window!.makeKeyAndVisible()
    window!.accessibilityIdentifier = "main window"
  }

  func sceneWillResignActive(_: UIScene) {
    rootViewModel.isRecording = false
  }

  func sceneDidEnterBackground(_: UIScene) {
    rootViewModel.isRecording = false
    rootViewModel.persistImageInBackground()
  }

  func sceneWillEnterForeground(_: UIScene) {
    rootViewModel.isRecording = false
    rootViewModel.motionUpdates = true
  }

  func sceneDidBecomeActive(_: UIScene) {
    rootViewModel.isRecording = false
    rootViewModel.motionUpdates = true
  }
}
