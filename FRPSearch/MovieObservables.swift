import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON

extension JSON {
    func toMovies() -> [Movie]? {
        if let results = self["results"].array {
            return results.map({ movieJSON in
                let movieImageURL = NSURL(string: movieJSON["artworkUrl100"].string ?? "")
                let movieName = movieJSON["trackName"].string
                return Movie(name: movieName, imageURL: movieImageURL)
            }).flatMap( { $0 } )
        }
        return nil
    }
}

struct MovieObservables {
    static func network(searchText text:String?) -> Observable<[Movie]> {
        guard let
            text = text?.stringByReplacingOccurrencesOfString(" ", withString: "+"),
            url = NSURL(string: "https://itunes.apple.com/search?term=\(text)&media=movie")
            where text.characters.count > 1
            else { return Observable.just([]) }
        return network(searchText: text, url: url)
    }
    
    private static func network(searchText text:String, url:NSURL) -> Observable<[Movie]> {
        return Observable.create({ observer in
            print("started request for \(text)")
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
                guard let response = response, data = data else {
                    observer.on(.Error(error ?? RxCocoaURLError.Unknown))
                    return
                }
                guard let _ = response as? NSHTTPURLResponse else {
                    observer.on(.Error(RxCocoaURLError.NonHTTPResponse(response: response)))
                    return
                }
                if let movies = JSON(data: data).toMovies() {
                    observer.onNext(movies)
                }
                observer.on(.Completed)
            }
            task.resume()
            return AnonymousDisposable {
                if let _ = task.response {
                    print("completed request for \(text)")
                } else {
                    task.cancel()
                    print("cancelled request for \(text)")
                }
            }
        })
    }
}