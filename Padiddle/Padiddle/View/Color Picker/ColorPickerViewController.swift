//
//  ColorPickerViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage
import UIKit

let colsPortrait = 2
let rowsPortrait = 3
let colsLandscape = 3
let rowsLandscape = 2

protocol ColorPickerDelegate: AnyObject {
    func colorPicked(_ color: ColorManager)
}

class ColorPickerViewController: UIViewController {

    enum ScrollPositionUpdateMode {
        case never
        case always
    }

    weak var delegate: ColorPickerDelegate?

    private let collectionView: UICollectionView
    private let pageControl: UIPageControl
    private let layout: ColorPickerLayout
    private let viewModel: ColorPickerViewModel

    private var currentSelection = IndexPath(item: 0, section: 0)
    private var pendingIndexPathToSelectAfterLayout: IndexPath?

    private func updateCurrentSelection(_ indexPath: IndexPath, updateScrollPosition: ScrollPositionUpdateMode) {
        currentSelection = indexPath

        switch updateScrollPosition {
        case .never: break
        case .always:
            scrollToPageWithCell(at: currentSelection)
        }
    }

    init(viewModel: ColorPickerViewModel, delegate: ColorPickerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        layout = ColorPickerLayout()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        pageControl = UIPageControl()

        super.init(nibName: nil, bundle: nil)

        collectionView.allowsMultipleSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self

        pageControl.numberOfPages = layout.numberOfPages
        pageControl.isExclusiveTouch = true
        pageControl.pageIndicatorTintColor = .pageIndicator
        pageControl.currentPageIndicatorTintColor = .pageIndicatorCurrentPage
        pageControl.addTarget(self, action: #selector(ColorPickerViewController.pageControlChanged), for: .valueChanged)

        title = L10n.colors
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        collectionView.contentInsetAdjustmentBehavior = .automatic

        collectionView.register(PickerCell.self, forCellWithReuseIdentifier: "cell")

        view.addSubview(collectionView)
        view.addSubview(pageControl)

        // Layout

        collectionView.horizontalAnchors == view.horizontalAnchors
        pageControl.horizontalAnchors == view.horizontalAnchors

        collectionView.topAnchor == view.safeAreaLayoutGuide.topAnchor
        pageControl.topAnchor == collectionView.bottomAnchor
        pageControl.bottomAnchor == view.safeAreaLayoutGuide.bottomAnchor

        // Need to set the scroll view’s content size before we can tell it to scroll.
        collectionView.contentSize = layout.collectionViewContentSize
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let pendingIndexPath = pendingIndexPathToSelectAfterLayout {
            updateCurrentSelection(pendingIndexPath, updateScrollPosition: .always)
            pendingIndexPathToSelectAfterLayout = nil
        }

        // Restore the previous selection in the collection view
        collectionView.selectItem(at: currentSelection, animated: false, scrollPosition: [])
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {

        adjustColumnsAndRows(newCollection)

        // Scroll to the correct page
        collectionView.contentOffset = CGPoint(x: CGFloat(viewModel.currentPage) * collectionView.frame.width, y: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let restoredIndex = viewModel.selectedIndex
        pendingIndexPathToSelectAfterLayout = IndexPath(item: restoredIndex, section: 0)

        adjustColumnsAndRows(traitCollection)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.selectItem(at: currentSelection, animated: false, scrollPosition: [])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollToPageWithCell(at: currentSelection)
    }

    // MARK: Action Handlers

    @objc func pageControlChanged() {
        let pageWidth = collectionView.frame.width
        let scrollTo = CGPoint(x: pageWidth * CGFloat(pageControl.currentPage), y: 0)
        collectionView.setContentOffset(scrollTo, animated: true)
    }

}

private extension ColorPickerViewController {

    func adjustColumnsAndRows(_ traitCollection: UITraitCollection) {
        if traitCollection.verticalSizeClass == .regular {
            layout.numberOfColumns = colsPortrait
            layout.numberOfRows = rowsPortrait
        }
        else {
            layout.numberOfColumns = colsLandscape
            layout.numberOfRows = rowsLandscape
        }
    }

    func scrollToPageWithCell(at indexPath: IndexPath) {
        guard collectionView.frame != .zero else { return }
        guard let cellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else { return }

        let pageWidth = collectionView.frame.width
        viewModel.currentPage = Int(floor(cellFrame.minX / pageWidth))
        pageControl.currentPage = viewModel.currentPage

        let scrollTo = CGPoint(x: pageWidth * CGFloat(pageControl.currentPage), y: 0)
        collectionView.setContentOffset(scrollTo, animated: false)
    }

}

extension ColorPickerViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = collectionView.frame.width
        viewModel.currentPage = Int(floor(collectionView.contentOffset.x / pageWidth))
        pageControl.currentPage = viewModel.currentPage
    }

}

extension ColorPickerViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.colorsToPick.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PickerCell else {
            fatalError("Cell registration was probably done incorrectly")
        }

        cell.title = viewModel.colorsToPick[indexPath.item].title

        cell.image = viewModel.imageForColorManager(viewModel.colorsToPick[indexPath.item])
        return cell
    }

}

extension ColorPickerViewController: UICollectionViewDelegate {

    // By default, the collection view allows deselection of selected cells
    // when they are tapped. To work around this, reselect the cell immediately
    // and treat it as a selection.
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if indexPath == currentSelection {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            delegate?.colorPicked(viewModel.selectedColorManager)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        viewModel.selectedIndex = indexPath.item

        if var selectedItems = collectionView.indexPathsForSelectedItems {
            selectedItems.remove(indexPath)
            for pathToDeselect in selectedItems {
                collectionView.deselectItem(at: pathToDeselect, animated: false)
            }
        }

        updateCurrentSelection(indexPath, updateScrollPosition: .always)
        delegate?.colorPicked(viewModel.selectedColorManager)
    }

}
