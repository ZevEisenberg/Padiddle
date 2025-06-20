import Foundation
import SwiftUI
import UIKit.UIImage

protocol ToolbarViewModelToolbarDelegate: AnyObject {
  func setToolbarVisible(_ visible: Bool, animated: Bool)
}

protocol ToolbarViewModelColorDelegate: AnyObject {
  func colorManagerPicked(_ colorManager: ColorManager)
}

@Observable
class ToolbarViewModel {
  var colorPickerViewModel: ColorPickerViewModel?

  let rootViewModel: RootViewModel

  @ObservationIgnored
  weak var toolbarDelegate: ToolbarViewModelToolbarDelegate?

  @ObservationIgnored
  weak var colorDelegate: ToolbarViewModelColorDelegate?

  required init(
    rootViewModel: RootViewModel,
    toolbarDelegate: ToolbarViewModelToolbarDelegate,
    colorDelegate: ToolbarViewModelColorDelegate
  ) {
    self.rootViewModel = rootViewModel
    self.toolbarDelegate = toolbarDelegate
    self.colorDelegate = colorDelegate
    self.colorPickerViewModel = ColorPickerViewModel(delegate: self)
  }

  func recordButtonTapped() {
    withAnimation(.snappy) {
      rootViewModel.isRecording.toggle()
    }
  }

  func clearTapped() {
    rootViewModel.clearTapped()
  }

  func getSnapshotImage(_ interfaceOrientation: UIInterfaceOrientation, destination: ImageDestination) -> ExportableImage {
    rootViewModel.getSnapshotImage(interfaceOrientation, destination: destination)
  }
}

extension ToolbarViewModel: RecordingDelegate {
  @objc func recordingStatusChanged(_ recording: Bool) {
    toolbarDelegate?.setToolbarVisible(!recording, animated: true)
  }
}

extension ToolbarViewModel: ColorPickerViewModelDelegate {
  func colorManagerPicked(_ colorManager: ColorManager) {
    colorDelegate?.colorManagerPicked(colorManager)
  }
}
