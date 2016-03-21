//: [Previous](@previous)

import UIKit
import Tapptitude

let items = NSArray(arrayLiteral: "Maria", "232", 23)
let dataSource = DataSource(items)
let stringCellController = CollectionCellController<String, UICollectionViewCell>(cellSize: CGSize(width: 50, height: 50))
stringCellController.minimumInteritemSpacing = 20
stringCellController.configureCell = { cell, content, indexPath in
    cell.backgroundColor = UIColor.redColor()
}
stringCellController.didSelectContent = { content, indexPath, collectionView in
    print("did select", content)
}


let numberCellController = CollectionCellController<Int, UICollectionViewCell>(cellSize: CGSize(width: 100, height: 50))

numberCellController.configureCell = { cell, content, indexPath in
    cell.backgroundColor = UIColor.blueColor()
}
numberCellController.didSelectContent = { content, indexPath, collectionView in
    print("did select", content)
}


let multiCellController = MultiCollectionCellController([stringCellController, numberCellController])

let feedController = CollectionFeedController()
feedController.dataSource = dataSource
feedController.cellController = multiCellController

import XCPlayground
XCPlaygroundPage.currentPage.liveView = feedController.view


//: [Next](@next)
