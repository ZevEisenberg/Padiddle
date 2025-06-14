//
//  ToolbarViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation
import UIKit.UIImage

protocol ToolbarViewModelToolbarDelegate: AnyObject {

    func setToolbarVisible(_ visible: Bool, animated: Bool)

}

protocol ToolbarViewModelColorDelegate: AnyObject {

    func colorManagerPicked(_ colorManager: ColorManager)

}

class ToolbarViewModel {

    var colorPickerViewModel: ColorPickerViewModel?

    let rootViewModel: RootViewModel

    weak var toolbarDelegate: ToolbarViewModelToolbarDelegate?
    weak var colorDelegate: ToolbarViewModelColorDelegate?

    required init(rootViewModel: RootViewModel, toolbarDelegate: ToolbarViewModelToolbarDelegate, colorDelegate: ToolbarViewModelColorDelegate) {
        self.rootViewModel = rootViewModel
        self.toolbarDelegate = toolbarDelegate
        self.colorDelegate = colorDelegate
        colorPickerViewModel = ColorPickerViewModel(delegate: self)
    }

    func recordButtonTapped() {
        rootViewModel.isRecording.toggle()
    }

    func clearTapped() {
        rootViewModel.clearTapped()
    }

    func getSnapshotImage(_ interfaceOrientation: UIInterfaceOrientation, completion: @escaping (EitherImage) -> Void) {
        rootViewModel.getSnapshotImage(interfaceOrientation, completion: completion)
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
