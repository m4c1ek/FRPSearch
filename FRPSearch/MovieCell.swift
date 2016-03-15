import UIKit
import Kingfisher

class MovieCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var movieName: UILabel!
    
    func setup(movie movie:Movie) {
        if let imageURL = movie.imageURL {
            imageView.kf_setImageWithURL(imageURL)
        }
        movieName.text = movie.name
    }
    
    func cancelImageLoading() {
        imageView.kf_cancelDownloadTask()
    }
}
