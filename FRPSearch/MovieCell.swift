import UIKit
import Kingfisher

class MovieCell: UICollectionViewCell {
    static let cellHeight:CGFloat = 58
    static let cellReuseIdentifier = "MovieCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var movieName: UILabel!
    
    func setup(movie movie:Movie) {
        if let imageURL = movie.imageURL {
            imageView.kf_setImageWithURL(imageURL)
        }
        movieName.text = movie.name
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf_cancelDownloadTask()
    }
}
