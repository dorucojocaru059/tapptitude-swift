//
//  DataSource.swift
//  tapptitude-swift
//
//  Created by Alexandru Tudose on 17/02/16.
//  Copyright © 2016 Tapptitude. All rights reserved.
//

import Foundation


public class DataSource : TTDataSource {
    lazy private var _content : [Any] = [Any]()
    
    public init(_ content : [Any]) {
        _content = content
    }
    
    public init(_ content : NSArray) {
        _content = content.map({$0 as Any})
    }
    
    public init() {
        _content = []
    }
    
    public var delegate : TTDataSourceDelegate?
    public var feed : TTDataFeed? {
        willSet {
            feed?.delegate = nil
        }
        didSet {
            feed?.delegate = self
        }
    }
    
    deinit {
        feed?.delegate = nil
    }
    
    public var content : [Any] {
        get {
            return _content
        }
    }
    
    public func hasContent() -> Bool {
        return _content.isEmpty == false
    }
    
    public func numberOfSections() -> Int {
        return 1
    }
    
    public func numberOfRowsInSection(section: Int) -> Int {
        return _content.count
    }
    
    public func objectAtIndexPath(indexPath: NSIndexPath) -> Any {
        return _content[indexPath.item]
    }
    
    public func indexPathForObject(object: Any) -> NSIndexPath? {
        //TODO: implement
        fatalError()
        
        // TODO: find a better way
//        let index = _content.indexOf({ (searchedItem) -> Bool in
//            return (searchedItem as Any) === object
//        })
//        
//        if index != nil {
//            return NSIndexPath(forItem: index!, inSection: 0)
//        } else {
//            return nil
//        }
    }
    
    public var dataSourceID : String?
}


public protocol TTDataSourceIncrementalChangesDelegate {
    func dataSourceWillChangeContent(dataSource: TTDataSource)
    
    func dataSource(dataSource: TTDataSource, didUpdateItemsAtIndexPaths indexPaths: [NSIndexPath])
    func dataSource(dataSource: TTDataSource, didDeleteItemsAtIndexPaths indexPaths: [NSIndexPath])
    func dataSource(dataSource: TTDataSource, didInsertItemsAtIndexPaths indexPaths: [NSIndexPath])
    func dataSource(dataSource: TTDataSource, didMoveItemsAtIndexPaths fromIndexPaths: [NSIndexPath], toIndexPaths: [NSIndexPath])
    
    func dataSource(dataSource: TTDataSource, didInsertSections addedSections: NSIndexSet)
    func dataSource(dataSource: TTDataSource, didDeleteSections deletedSections: NSIndexSet)
    func dataSource(dataSource: TTDataSource, didUpdateSections updatedSections: NSIndexSet)
    
    func dataSourceDidChangeContent(dataSource: TTDataSource)
}


extension DataSource : TTDataFeedDelegate {
    public func dataFeed(dataFeed: TTDataFeed?, failedWithError error: NSError) {
        if let delegate = delegate as? TTDataFeedDelegate {
            delegate.dataFeed(dataFeed, failedWithError: error)
        }
    }
    
    public func dataFeed(dataFeed: TTDataFeed?, didReloadContent content: [Any]?) {
        // pass delegate message
        if let delegate = delegate as? TTDataFeedDelegate {
            delegate.dataFeed(dataFeed, didReloadContent: content)
        }
        
        let wasEmpty = content?.isEmpty == true
        _content = content ?? []
        let isEmpty = _content.isEmpty
        
        let incrementalInserts = delegate is TTDataSourceIncrementalChangesDelegate
        if incrementalInserts {
            let ignore = wasEmpty && isEmpty
            if !ignore {
                let delegate = self.delegate as! TTDataSourceIncrementalChangesDelegate
                delegate.dataSourceWillChangeContent(self)
                delegate.dataSource(self, didUpdateSections: NSIndexSet(index: 0))
                delegate.dataSourceDidChangeContent(self)
            }
        } else {
            delegate?.dataSourceDidReloadContent(self)
        }
    }
    
    public func dataFeed(dataFeed: TTDataFeed?, didLoadMoreContent content: [Any]?) {
        // pass delegate message
        if let delegate = delegate as? TTDataFeedDelegate {
            delegate.dataFeed(dataFeed, didLoadMoreContent: content)
        }
        
        let incrementalInserts = delegate is TTDataSourceIncrementalChangesDelegate
        var indexPaths = [NSIndexPath]();
        
        if let content = content {
            _content.appendContentsOf(content)
            
            if incrementalInserts {
                indexPaths = content.enumerate().map({ (index, _) -> NSIndexPath in
                    return NSIndexPath(forItem: index, inSection: 0)
                })
            }
        }
        
        if incrementalInserts {
            if !indexPaths.isEmpty {
                let delegate = self.delegate as! TTDataSourceIncrementalChangesDelegate
                delegate.dataSourceWillChangeContent(self)
                delegate.dataSource(self, didInsertItemsAtIndexPaths: indexPaths)
                delegate.dataSourceDidChangeContent(self)
            }
        } else if (content?.isEmpty == false){
            delegate?.dataSourceDidLoadMoreContent(self)
        } else {
            // no content loaded
        }
    }
    
    public func dataFeed(dataFeed: TTDataFeed?, isReloading: Bool) {
        if let delegate = delegate as? TTDataFeedDelegate {
            delegate.dataFeed(dataFeed, isReloading: isReloading)
        }
    }
    
    public func dataFeed(dataFeed: TTDataFeed?, isLoadingMore: Bool) {
        if let delegate = delegate as? TTDataFeedDelegate {
            delegate.dataFeed(dataFeed, isLoadingMore: isLoadingMore)
        }
    }
}



extension DataSource : TTDataSourceMutable {
    
    private func editContentWithBlock(editBlock: ( inout content : [Any], delegate: TTDataSourceIncrementalChangesDelegate?)->Void) {
        let incrementalUpdates = delegate is TTDataSourceIncrementalChangesDelegate
        if (incrementalUpdates) {
            let delegate = self.delegate as! TTDataSourceIncrementalChangesDelegate
            delegate.dataSourceWillChangeContent(self)
            editBlock(content: &_content, delegate: delegate);
            delegate.dataSourceDidChangeContent(self)
        } else {
            editBlock(content: &_content, delegate: nil);
            delegate?.dataSourceDidReloadContent(self)
        }
    }
    
    public func addContent(content: Any) {
        editContentWithBlock { (_content, delegate) -> Void in
            _content.append(content)
            let indexPath = NSIndexPath(forItem: _content.count, inSection: 0)
            delegate?.dataSource(self, didInsertItemsAtIndexPaths: [indexPath])
        }
    }
    
    public func addContentFromArray(array: [Any]) {
        editContentWithBlock { (_content, delegate) -> Void in
            let startIndex = _content.count
            let indexPaths = array.enumerate().map({ (index, _) -> NSIndexPath in
                return NSIndexPath(forItem: startIndex + index, inSection: 0)
            })
            
            _content.appendContentsOf(array)
            delegate?.dataSource(self, didInsertItemsAtIndexPaths: indexPaths)
        }
    }
    
    public func insertContent(content: Any, atIndexPath indexPath: NSIndexPath) {
        editContentWithBlock { (_content, delegate) -> Void in
            _content.insert(content, atIndex: indexPath.item)
            delegate?.dataSource(self, didInsertItemsAtIndexPaths: [indexPath])
        }
    }
    
    public func moveContentFromIndexPath(fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        editContentWithBlock { (_content, delegate) -> Void in
            let item = _content[fromIndexPath.item]
            _content.removeAtIndex(fromIndexPath.item)
            
            var toIndex = toIndexPath.item
            if toIndexPath.item > fromIndexPath.item {
                toIndex -= 1
            }
            
            _content.insert(item, atIndex: toIndex)
            
            delegate?.dataSource(self, didMoveItemsAtIndexPaths: [fromIndexPath], toIndexPaths: [toIndexPath])
        }
    }
    
    public func removeContentFromIndexPath(indexPath: NSIndexPath) {
        editContentWithBlock { (_content, delegate) -> Void in
            _content.removeAtIndex(indexPath.item)
            delegate?.dataSource(self, didDeleteItemsAtIndexPaths: [indexPath])
        }
    }
    
    public func removeContent(content: Any) {
        if let indexPath = self.indexPathForObject(content) {
            self.removeContentFromIndexPath(indexPath)
        } else {
            print("Content not found \(content) in dataSource")
        }
    }
    
    public func replaceContentAtIndexPath(indexPath: NSIndexPath, content: Any) {
        editContentWithBlock { (_content, delegate) -> Void in
            _content[indexPath.item] = content
            delegate?.dataSource(self, didUpdateItemsAtIndexPaths: [indexPath])
        }
    }
}