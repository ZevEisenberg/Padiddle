//
//  ColorPickerViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

let colsPortrait = 2
let rowsPortrait = 3
let colsLandscape = 3
let rowsLandscape = 2

class ColorPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    private let collectionView: UICollectionView
    private let pageControl: UIPageControl
    private let layout: ColorPickerLayout
    private let viewModel: ColorPickerViewModel

    init(viewModel: ColorPickerViewModel) {
        self.viewModel = viewModel
        layout = ColorPickerLayout()

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        pageControl = UIPageControl()

        super.init(nibName: nil, bundle: nil)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .whiteColor()
        collectionView.pagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = layout.numberOfPages
        pageControl.exclusiveTouch = true
        pageControl.pageIndicatorTintColor = UIColor(white: 0.6, alpha: 1)
        pageControl.currentPageIndicatorTintColor = UIColor(white: 0.2, alpha: 1)
        pageControl.addTarget(self, action: "pageControlChanged", forControlEvents: .ValueChanged)

        title = NSLocalizedString("Color Settings", comment: "Title of a view that lets you choose a color scheme")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(__FUNCTION__) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()
        automaticallyAdjustsScrollViewInsets = false

        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")

        view.addSubview(collectionView)
        view.addSubview(pageControl)

        // Layout

        collectionView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        collectionView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true

        pageControl.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        pageControl.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true

        topLayoutGuide.bottomAnchor.constraintEqualToAnchor(collectionView.topAnchor).active = true
        collectionView.bottomAnchor.constraintEqualToAnchor(pageControl.topAnchor).active = true
        pageControl.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor).active = true

        //--------------------------------------------------
        // Need to set the scroll view’s content size
        // before we can tell it to scroll.
        //--------------------------------------------------
        collectionView.contentSize = layout.collectionViewContentSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        adjustColumnsAndRows(newCollection)

        // Scroll to the correct page
        collectionView.contentOffset = CGPoint(x: CGFloat(viewModel.currentPage) * CGRectGetWidth(collectionView.frame), y: 0);
    }

    // MARK: Action Handlers

    func pageControlChanged() {
        let pageWidth = CGRectGetWidth(collectionView.frame)
        let scrollTo = CGPoint(x: pageWidth * CGFloat(pageControl.currentPage), y: 0)
        collectionView.setContentOffset(scrollTo, animated:true)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.colorsToPick.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        cell.contentView.backgroundColor = .greenColor()
        return cell
    }

    // MARK: UICollectionViewDelegate

    // MARK: Private

    private func adjustColumnsAndRows(traitCollection: UITraitCollection) {
        if traitCollection.verticalSizeClass == .Regular {
            layout.numberOfColumns = colsPortrait
            layout.numberOfRows = rowsPortrait
        }
        else {
            layout.numberOfColumns = colsLandscape
            layout.numberOfRows = rowsLandscape
        }
    }
}
