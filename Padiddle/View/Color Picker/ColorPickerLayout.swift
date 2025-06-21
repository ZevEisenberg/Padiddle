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
  private var layoutInfo = [IndexPath: UICollectionViewLayoutAttributes]()

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
      for section in 0..<sectionCount {
        if let itemCount = collectionView?.numberOfItems(inSection: section) {
          for item in 0..<itemCount {
            let indexPath = IndexPath(item: item, section: section)

            let itemAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            itemAttributes.frame = frameForItemAtIndexPath(indexPath)

            cellLayoutInfo[indexPath] = itemAttributes
          }
        }
      }

      layoutInfo = cellLayoutInfo
    }
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var allAtributes = [UICollectionViewLayoutAttributes]()

    for (_, attributes) in layoutInfo where rect.intersects(attributes.frame) {
      allAtributes.append(attributes)
    }

    return allAtributes
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    layoutInfo[indexPath]
  }

  override var collectionViewContentSize: CGSize {
    guard let collectionView else {
      return .zero
    }

    let height = collectionView.frame.height

    let width = collectionView.frame.width * CGFloat(numberOfPages)

    return CGSize(width: width, height: height)
  }
}

private extension ColorPickerLayout {
  func frameForItemAtIndexPath(_ indexPath: IndexPath) -> CGRect {
    guard let collectionView else {
      return .zero
    }

    let itemsPerPage = numberOfColumns * numberOfRows
    let page = indexPath.item / itemsPerPage
    let indexRelativeToThisPage = indexPath.item % itemsPerPage

    let column = indexRelativeToThisPage % numberOfColumns
    let row = indexRelativeToThisPage / numberOfColumns

    let spaceForColumns = (
      collectionView.frame.width -
        pageInsets.left -
        pageInsets.right -
        collectionView.safeAreaInsets.left -
        collectionView.safeAreaInsets.right -
        CGFloat(numberOfColumns - 1) * spacing)
    let columnWidth = spaceForColumns / CGFloat(numberOfColumns)

    let spaceForRows = (
      collectionView.frame.height -
        pageInsets.top -
        pageInsets.bottom -
        collectionView.safeAreaInsets.top -
        collectionView.safeAreaInsets.bottom -
        CGFloat(numberOfRows - 1) * spacing)
    let rowHeight = spaceForRows / CGFloat(numberOfRows)

    let originX = floor(
      pageInsets.left +
        collectionView.safeAreaInsets.left +
        (columnWidth + spacing) * CGFloat(column) +
        CGFloat(page) * collectionView.frame.width)

    let originY = floor(
      pageInsets.top +
        collectionView.safeAreaInsets.top +
        (rowHeight + spacing) * CGFloat(row))

    let frame = CGRect(x: originX, y: originY, width: floor(columnWidth), height: floor(rowHeight))
    return frame
  }
}
