//: [Previous](@previous)

import UIKit
import Tapptitude

extension URLSessionTask: TTCancellable {
    
}

let url = URL(string: "https://httpbin.org/get")
var url_request = URLRequest(url: url!)

class API {
    class func getPage(callback: @escaping TTCallback<[String]> ) -> TTCancellable? {
        let task = URLSession.shared.dataTask(with: url_request) { data , response , error  in
            let stringResponse = data != nil ? String(data: data!, encoding: String.Encoding.utf8) : nil
            let items: [String]? = stringResponse != nil ? [stringResponse!] : nil
            print(error as Any)
            
            DispatchQueue.main.async {
                if let items = items {
                    callback(.success(items))
                } else {
                    callback(.failure(error!))
                }
            }
        }
        task.resume()
        
        return task
    }
}

// short version
let feed = DataFeed(load: API.getPage)
// long version
//let feed = DataFeed { (callback) -> TTCancellable? in
//    return API.getPage(callback: callback)
//}
let feedController = CollectionFeedController()
feedController.dataSource = DataSource<String>(feed: feed)
feedController.cellController = BrownTextCellController()


import PlaygroundSupport
feedController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
PlaygroundPage.current.liveView = feedController.view
PlaygroundPage.current.needsIndefiniteExecution = true
//: [Next](@next)
