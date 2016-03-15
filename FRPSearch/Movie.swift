import Foundation

struct Movie: Equatable {
    var imageURL:NSURL?
    var name:String?
    
    init(name:String?, imageURL:NSURL?) {
        self.name = name
        self.imageURL = imageURL
    }
}

// MARK: Equatable
func ==(lhs: Movie, rhs: Movie) -> Bool {
    return lhs.imageURL == rhs.imageURL && lhs.name == rhs.name
}