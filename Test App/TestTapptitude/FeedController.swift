//
//  FeedController.swift
//  TestTapptitude
//
//  Created by Alexandru Tudose on 20/02/16.
//  Copyright © 2016 Tapptitude. All rights reserved.
//

import UIKit
import Tapptitude

extension URLSessionTask: TTCancellable {
    
}


class TestViewController : UIViewController, CollectionController {
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var reloadIndicatorView: UIActivityIndicatorView?
    @IBOutlet var emptyView: UIView?
    
    var cellController = TextItemCellController()
    lazy var dataSource = DataSource<String>(load: API.getBin)
    var collectionController = CollectionFeedController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionController()
        
        dataSource.insert("Maria", at: IndexPath(item: 0, section: 0))
        let _ = dataSource[0].appending("2323 ")
    }
}


protocol CollectionController: class {
    associatedtype DataSourceType: TTDataSource
    associatedtype CellControllerType: TTCollectionCellControllerProtocol
    associatedtype CollectionControllerType: CollectionFeedController
    
    var dataSource: DataSourceType {get set}
    var cellController: CellControllerType {get set}
    var collectionController: CollectionControllerType {get set}
    
    weak var collectionView: UICollectionView? {get set}
    
    weak var reloadIndicatorView: UIActivityIndicatorView? {get set}
    var emptyView: UIView? {get set} //set from XIB or overwrite
}

extension CollectionController where Self: UIViewController {
    func setupCollectionController() {
        collectionView?.dataSource = collectionController
        collectionView?.delegate = collectionController
        collectionController.reloadIndicatorView = reloadIndicatorView
        collectionController.collectionView = collectionView
        
        collectionController.cellController = cellController
        cellController.parentViewController = self
        collectionController.dataSource = dataSource
    }
}

