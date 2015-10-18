//
//  ToolbarViewModel.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Foundation

protocol ToolbarViewModelDelegate:
class {
    func setToolbarVisible(visible: Bool, animated: Bool)
}

class ToolbarViewModel: RecordingDelegate {
    let colorPickerVieModel = ColorPickerViewModel()

    let rootViewModel: RootViewModel

    weak var delegate: ToolbarViewModelDelegate?

    required init(rootViewModel: RootViewModel, delegate: ToolbarViewModelDelegate) {
        self.rootViewModel = rootViewModel
        self.delegate = delegate
    }

    func recordButtonTapped() {
        rootViewModel.recording = !rootViewModel.recording
    }

    // MARK: RecordingDelegate

    @objc func recordingStatusChanged(recording: Bool) {
        delegate?.setToolbarVisible(!recording, animated: true)
    }
}
