//
//  ColorPickerLayout.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

private let spacing: CGFloat = 10

class ColorPickerLayout: UICollectionViewLayout {
    var numberOfColumns: Int = 2 {
        didSet {
            invalidateLayout()
        }
    }
    var numberOfRows: Int = 3 {
        didSet {
            invalidateLayout()
        }
    }
    private let pageInsets = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    private var layoutInfo = [NSIndexPath: UICollectionViewLayoutAttributes]()

    var numberOfPages: Int {
        let itemsPerPage = numberOfColumns * numberOfRows;
        let numberOfItems = collectionView!.numberOfItemsInSection(0)
        var pageCount = numberOfItems / itemsPerPage
        if numberOfItems % itemsPerPage != 0 {
            pageCount++;
        }
        return pageCount;
    }

    override func prepareLayout() {
        var cellLayoutInfo = [NSIndexPath: UICollectionViewLayoutAttributes]()

        if let sectionCount = collectionView?.numberOfSections() {
            var indexPath: NSIndexPath?

            for section in 0..<sectionCount {
                if let itemCount = collectionView?.numberOfItemsInSection(section) {

                    for item in 0..<itemCount {
                        indexPath = NSIndexPath(forItem: item, inSection: section)

                        guard let definiteIndexPath = indexPath else {
                            fatalError()
                        }

                        let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: definiteIndexPath)
                        itemAttributes.frame = frameForItemAtIndexPath(definiteIndexPath)

                        cellLayoutInfo[definiteIndexPath] = itemAttributes
                    }
                }
            }

            layoutInfo = cellLayoutInfo
        }
    }

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var allAtributes = [UICollectionViewLayoutAttributes]()

        for (_, attributes) in layoutInfo {
            if CGRectIntersectsRect(rect, attributes.frame) {
                allAtributes.append(attributes)
            }
        }

        return allAtributes
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutInfo[indexPath];
    }

    override func collectionViewContentSize() -> CGSize {
        guard let collectionView = collectionView else {
            return CGSize()
        }

        let height = CGRectGetHeight(collectionView.frame)

        let width = CGRectGetWidth(collectionView.frame) * CGFloat(numberOfPages);

        return CGSize(width: width, height: height)
    }

    // MARK: Private
    private func frameForItemAtIndexPath(indexPath: NSIndexPath) -> CGRect {

        guard let collectionView = collectionView else {
            return CGRect.zero
        }

        let itemsPerPage = numberOfColumns * numberOfRows;
        let page = indexPath.item / itemsPerPage;
        let indexRelativeToThisPage = indexPath.item % itemsPerPage;

        let column = indexRelativeToThisPage % numberOfColumns
        let row    = indexRelativeToThisPage / numberOfColumns

        let spaceForColumns = (
            CGRectGetWidth(collectionView.frame) -
            pageInsets.left -
            pageInsets.right -
            CGFloat(numberOfColumns - 1) * spacing)
        let columnWidth = spaceForColumns / CGFloat(numberOfColumns)

        let spaceForRows = (
            CGRectGetHeight(collectionView.frame) -
            pageInsets.top -
            pageInsets.bottom -
            CGFloat(numberOfRows - 1) * spacing);
        let rowHeight = spaceForRows / CGFloat(numberOfRows)

        let originX = floor(
            pageInsets.left +
            (columnWidth + spacing) * CGFloat(column) +
            CGFloat(page) * CGRectGetWidth(collectionView.frame))

        let originY = floor(
            pageInsets.top +
            (rowHeight + spacing) * CGFloat(row))

        let frame = CGRect(x: originX, y: originY, width: floor(columnWidth), height: floor(rowHeight))
        return frame
    }
}
