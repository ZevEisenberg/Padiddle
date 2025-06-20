import Foundation
import UIKit.UIApplication

@objc protocol RecordingDelegate: AnyObject {
  func recordingStatusChanged(_ recording: Bool)
  @objc optional func motionUpdatesStatusChanged(_ updates: Bool)
  @objc optional func persistImageInBackground()
}

protocol RootColorManagerDelegate: AnyObject {
  func colorManagerPicked(_ colorManager: ColorManager)
}

@Observable
class RootViewModel {
  private var recordingDelegates = [Weak<RecordingDelegate>]()
  weak var rootColorManagerDelegate: RootColorManagerDelegate?
  weak var drawingViewController: DrawingViewController?

  init(rootColorManagerDelegate: RootColorManagerDelegate) {
    self.rootColorManagerDelegate = rootColorManagerDelegate
  }

  var isRecording = false {
    didSet {
      if oldValue != isRecording {
        for delegate in recordingDelegates {
          delegate.value?.recordingStatusChanged(isRecording)
        }
      }
    }
  }

  var motionUpdates = false {
    didSet {
      if oldValue != motionUpdates {
        for delegate in recordingDelegates {
          delegate.value?.motionUpdatesStatusChanged?(motionUpdates)
        }
      }
    }
  }

  func persistImageInBackground() {
    for delegate in recordingDelegates {
      delegate.value?.persistImageInBackground?()
    }
  }

  func addRecordingDelegate(_ delegate: RecordingDelegate) {
    recordingDelegates.append(Weak(value: delegate))
  }

  func getSnapshotImage(_ interfaceOrientation: UIInterfaceOrientation, destination: ImageDestination) -> ExportableImage {
    guard let drawingViewController else {
      fatalError("Not having a drawing view controller would represent a programmer error")
    }
    return drawingViewController.getSnapshotImage(interfaceOrientation: interfaceOrientation, destination: destination)
  }

  func clearTapped() {
    drawingViewController?.clearTapped()
  }
}

extension RootViewModel: ToolbarViewModelColorDelegate {
  func colorManagerPicked(_ colorManager: ColorManager) {
    rootColorManagerDelegate?.colorManagerPicked(colorManager)
  }
}
