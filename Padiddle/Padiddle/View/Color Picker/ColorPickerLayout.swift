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
    fileprivate let pageInsets = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    fileprivate var layoutInfo = [IndexPath: UICollectionViewLayoutAttributes]()

    var numberOfPages: Int {
        let itemsPerPage = numberOfColumns * numberOfRows
        let numberOfItems = collectionView!.numberOfItems(inSection: 0)
        var pageCount = numberOfItems / itemsPerPage
        if numberOfItems % itemsPerPage != 0 {
            pageCount += 1
        }
        return pageCount
    }

    override func prepare() {
        var cellLayoutInfo = [IndexPath: UICollectionViewLayoutAttributes]()

        if let sectionCount = collectionView?.numberOfSections {
            var indexPath: IndexPath?

            for section in 0..<sectionCount {
                if let itemCount = collectionView?.numberOfItems(inSection: section) {

                    for item in 0..<itemCount {
                        indexPath = IndexPath(item: item, section: section)

                        guard let definiteIndexPath = indexPath else {
                            fatalError()
                        }

                        let itemAttributes = UICollectionViewLayoutAttributes(forCellWith: definiteIndexPath)
                        itemAttributes.frame = frameForItemAtIndexPath(definiteIndexPath)

                        cellLayoutInfo[definiteIndexPath] = itemAttributes
                    }
                }
            }

            layoutInfo = cellLayoutInfo
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var allAtributes = [UICollectionViewLayoutAttributes]()

        for (_, attributes) in layoutInfo {
            if rect.intersects(attributes.frame) {
                allAtributes.append(attributes)
            }
        }

        return allAtributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutInfo[indexPath]
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return CGSize.zero
        }

        let height = collectionView.frame.height

        let width = collectionView.frame.width * CGFloat(numberOfPages)

        return CGSize(width: width, height: height)
    }
}

private extension ColorPickerLayout {
    func frameForItemAtIndexPath(_ indexPath: IndexPath) -> CGRect {

        guard let collectionView = collectionView else {
            return CGRect.zero
        }

        let itemsPerPage = numberOfColumns * numberOfRows
        let page = (indexPath as IndexPath).item / itemsPerPage
        let indexRelativeToThisPage = (indexPath as IndexPath).item % itemsPerPage

        let column = indexRelativeToThisPage % numberOfColumns
        let row    = indexRelativeToThisPage / numberOfColumns

        let spaceForColumns = (
            collectionView.frame.width -
                pageInsets.left -
                pageInsets.right -
                CGFloat(numberOfColumns - 1) * spacing)
        let columnWidth = spaceForColumns / CGFloat(numberOfColumns)

        let spaceForRows = (
            collectionView.frame.height -
                pageInsets.top -
                pageInsets.bottom -
                CGFloat(numberOfRows - 1) * spacing)
        let rowHeight = spaceForRows / CGFloat(numberOfRows)

        let originX = floor(
            pageInsets.left +
                (columnWidth + spacing) * CGFloat(column) +
                CGFloat(page) * collectionView.frame.width)

        let originY = floor(
            pageInsets.top +
                (rowHeight + spacing) * CGFloat(row))

        let frame = CGRect(x: originX, y: originY, width: floor(columnWidth), height: floor(rowHeight))
        return frame
    }
}
