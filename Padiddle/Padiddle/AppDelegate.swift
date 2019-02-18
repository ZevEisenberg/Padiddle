//
//  AppDelegate.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

#if DEBUG
    import SimulatorStatusMagic
#endif
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var drawingViewController: DrawingViewController?
    var toolbarViewController: ToolbarViewController?
    var rootViewModel: RootViewModel!

    // Private Properties

    private let spinManager = SpinManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UIApplication.shared.enableAdaptiveContentSizeMonitor()

        toolbarViewController = ToolbarViewController(spinManager: spinManager)

        let drawingViewModel = DrawingViewModel(
            maxRadius: UIScreen.main.shortestSide,
            contextSize: CGSize(width: UIScreen.main.longestSide, height: UIScreen.main.longestSide),
            contextScale: UIScreen.main.scale,
            spinManager: spinManager
        )

        rootViewModel = RootViewModel(rootColorManagerDelegate: drawingViewModel)

        let toolbarViewModel = ToolbarViewModel(rootViewModel: rootViewModel, toolbarDelegate: toolbarViewController!, colorDelegate: rootViewModel)

        toolbarViewController?.viewModel = toolbarViewModel

        rootViewModel.rootColorManagerDelegate = drawingViewModel

        drawingViewController = DrawingViewController(viewModel: drawingViewModel)

        rootViewModel.drawingViewController = drawingViewController

        rootViewModel.addRecordingDelegate(toolbarViewModel)
        rootViewModel.addRecordingDelegate(drawingViewModel)

        let rootViewController = RootViewController(viewModel: rootViewModel, pinnedViewController: drawingViewController!, rotatingViewController: toolbarViewController!)
        rootViewController.view.accessibilityIdentifier = "root view"

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        window?.accessibilityIdentifier = "main window"

        #if DEBUG
            if Defaults.snapshotMode {
                SDStatusBarManager.sharedInstance().enableOverrides()
            }
        #endif

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        rootViewModel.recording = false
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        rootViewModel.recording = false
        rootViewModel.persistImageInBackground()
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        rootViewModel.recording = false
        rootViewModel.motionUpdates = true
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        rootViewModel.recording = false
        rootViewModel.motionUpdates = true
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
