//
//  CircularCollectionController.swift
//  NDetailSlideshowExample
//
//  Created by Efraim Budusan on 9/27/16.
//  Copyright © 2016 Efraim Budusan. All rights reserved.
//

import Foundation
import Tapptitude
import UIKit

class CircularCollectionController: CollectionFeedController {
    
    var sliderTimeInterval = 7.0 { // 0 to disable it
        didSet {
            if oldValue != sliderTimeInterval {
                configureTimer()
            }
        }
    }
    var content: [AnyObject] = [] {
        didSet {
            pageControl?.numberOfPages = content.count
            pageControl?.hidden = content.count < 2
            
            var circularContent = content
            if circularContent.count > 1 {
                circularContent.append(content.first!)
                circularContent.insert(content.last!, atIndex: 0)
            }
            self.dataSource = DataSource(circularContent)
            
            if circularContent.count > 1 {
                if collectionView?.window == nil {
                    toDisplayPage = 0
                } else {
                    displayedPage = 0
                    configureTimer()
                }
            }
        }
    }
    private var toDisplayPage: Int = -1 //ingore
    
    @IBOutlet weak var pageControl: UIPageControl?
    
    var userDidScroll = false
    var displayedPage: Int {
        get {
            let pageWidth = collectionView!.bounds.size.width
            let page = Int(floor((collectionView!.contentOffset.x / pageWidth)))
            let itemsCount = content.count
            if itemsCount > 1 {
                return page == 0 ? (itemsCount - 1) : (page == itemsCount + 1 ? 0 : page - 1)
            } else {
                return 0
            }
        }
        set {
            pageControl?.currentPage = newValue
            let item = newValue + (content.count > 1 ? 1 : 0)
            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            self.collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
        }
    }
    
    var lastContentOffsetX = CGFloat.min
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let count = dataSource!.content.count
        if count < 2 {
            return
        }
        
        // We can ignore the first time scroll,
        // because it is caused by the call scrollToItemAtIndexPath: in ViewWillAppear
        if (CGFloat.min == lastContentOffsetX) {
            lastContentOffsetX = scrollView.contentOffset.x
            return;
        }
        
        let currentOffsetX = scrollView.contentOffset.x
        let currentOffsetY = scrollView.contentOffset.y
        
        let pageWidth = scrollView.bounds.size.width
        let offset = pageWidth * CGFloat(count - 2)
        
        // the first page(showing the last item) is visible and user's finger is still scrolling to the right
        if (currentOffsetX < pageWidth && lastContentOffsetX > currentOffsetX) {
            lastContentOffsetX = currentOffsetX + offset;
            scrollView.contentOffset = CGPoint(x: lastContentOffsetX, y: currentOffsetY)
        }
            // the last page (showing the first item) is visible and the user's finger is still scrolling to the left
        else if (currentOffsetX > offset && lastContentOffsetX < currentOffsetX) {
            lastContentOffsetX = currentOffsetX - offset;
            scrollView.contentOffset = CGPoint(x: lastContentOffsetX, y: currentOffsetY)
        } else {
            lastContentOffsetX = currentOffsetX;
        }
        
        pageControl?.currentPage = displayedPage
        
        //        let collectionView = self.collectionView!
        //        // Calculate where the collection view should be at the right-hand end item
        //        let count = dataSource!.content.count
        //        let contentOffsetWhenFullyScrolledRight = collectionView.frame.width * (CGFloat(count - 1))
        //
        //        if scrollView.contentOffset.x == contentOffsetWhenFullyScrolledRight {
        //
        //            // user is scrolling to the right from the last item to the 'fake' item 1.
        //            // reposition offset to show the 'real' item 1 at the left-hand end of the collection view
        //
        //            let indexPath = NSIndexPath(forItem: 1, inSection: 0)
        //
        //            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: false)
        //        } else if scrollView.contentOffset.x == 0  {
        //
        //            // user is scrolling to the left from the first item to the fake 'item N'.
        //            // reposition offset to show the 'real' item N at the right end end of the collection view
        //
        //            let indexPath = NSIndexPath(forItem: count - 2, inSection: 0)
        //            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: false)
        //        }
    }
    
    func scrollToNextPageAnimated() {
        if let visibleIndex = collectionView?.indexPathsForVisibleItems().first {
            var currentPage = visibleIndex.row + 1
            if currentPage >= dataSource?.numberOfItems(inSection: 0) {
                currentPage = 1
            }
            
            let index = NSIndexPath(forItem: currentPage, inSection: 0)
            collectionView?.scrollToItemAtIndexPath(index, atScrollPosition: .Right, animated: true)
        }
        
        configureTimer()
    }
    
    var timer: NSTimer!
    
    deinit {
        timer?.invalidate()
    }
    
    func configureTimer() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
        
        if content.count > 1 && !userDidScroll && sliderTimeInterval > 0.0 {
            animateProgressBar()
            
            timer = NSTimer(timeInterval: sliderTimeInterval, target: self, selector: #selector(CircularCollectionController.scrollToNextPageAnimated), userInfo: nil, repeats: false)
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        userDidScroll = true
        if timer != nil {
            timer.invalidate()
            
            if let progressBarView = progressBarView {
                progressBarView.layer.removeAllAnimations()
                let frame = progressBarView.bounds
                progressBarView.frame = CGRectMake(frame.origin.x, frame.origin.y, scrollView.frame.width, frame.height) //width 0
                //                progressBarView.frame = frame
            }
        }
    }
    
    
    var progressBarView: UIView?
    func animateProgressBar() {
        guard let progressBarView = progressBarView else {
            return
        }
        
        if let frame = progressBarView.superview?.bounds {
            progressBarView.frame = frame
            
            UIView.animateWithDuration(sliderTimeInterval) {
                progressBarView.frame = CGRectMake(frame.origin.x, frame.origin.y, 0, frame.height)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if toDisplayPage >= 0 {
            displayedPage = toDisplayPage
            configureTimer()
            toDisplayPage = -1
        }
    }
}