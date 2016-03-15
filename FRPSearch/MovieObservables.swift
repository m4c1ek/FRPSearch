import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON

struct MovieObservables {
    static func network(searchText text:String?) -> Observable<[Movie]> {
        guard let text = text, url = NSURL(string: "https://itunes.apple.com/search?term=\(text)&media=movie") where text.characters.count > 1 else { return Observable.just([]) }
        return Observable.create({ observer in
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
                guard let response = response, data = data else {
                    observer.on(.Error(error ?? RxCocoaURLError.Unknown))
                    return
                }
                guard let _ = response as? NSHTTPURLResponse else {
                    observer.on(.Error(RxCocoaURLError.NonHTTPResponse(response: response)))
                    return
                }
                let json = JSON(data: data)
                if let results = json["results"].array {
                    let movies = results.map({ movieJSON in
                        return Movie(name: movieJSON["trackName"].string, imageURL: NSURL(string: movieJSON["artworkUrl60"].string!))
                    }).flatMap( { $0 } )
                    observer.onNext(movies)
                }
                observer.on(.Completed)
            }
            task.resume()
            return AnonymousDisposable {
                task.cancel()
            }
        })
    }
}