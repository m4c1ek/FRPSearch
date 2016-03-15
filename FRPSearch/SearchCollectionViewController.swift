import UIKit
import RxSwift
import Dwifft

private let reuseIdentifier = "Cell"

class SearchCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet var searchBar: UISearchBar!
    var movies:[Movie] = []
    var disposable:Disposable?
    override func viewDidLoad() {
        super.viewDidLoad()
        let moviesObservable = searchBar.rx_text.throttle(0.3, scheduler: MainScheduler.instance).flatMapLatest { text in
            return MovieObservables.network(searchText: text)
        }.share()
        
        disposable = Observable.zip(moviesObservable, [Observable.just(movies), moviesObservable].concat()) { $0 }
            .observeOn(MainScheduler.instance)
            .subscribeNext { [weak self] (currentMovies, previousMovies) -> Void in
            self?.movies = currentMovies
            self?.updateMovies(currentMovies:currentMovies,previousMovies:previousMovies)
        }
    }
    
    private func updateMovies(currentMovies currentMovies:[Movie], previousMovies:[Movie]) {
        let diff = previousMovies.diff(currentMovies)
        let insertedIndexPaths = diff.insertions.map { insertDiff -> NSIndexPath? in
            var indexPath:NSIndexPath?
            if case .Insert(let i, _) = insertDiff {
                indexPath = NSIndexPath(forItem: i, inSection: 0)
            }
            return indexPath
        }.flatMap({ $0 })
        let deletedIndexPaths = diff.deletions.map { deleteDiff -> NSIndexPath? in
            var indexPath:NSIndexPath?
            if case .Delete(let i, _) = deleteDiff {
                indexPath = NSIndexPath(forItem: i, inSection: 0)
            }
            return indexPath
        }.flatMap({ $0 })
        
        self.collectionView?.performBatchUpdates({ () -> Void in
            if deletedIndexPaths.count > 0 {
                self.collectionView?.deleteItemsAtIndexPaths(deletedIndexPaths)
            }
            if insertedIndexPaths.count > 0 {
                self.collectionView?.insertItemsAtIndexPaths(insertedIndexPaths)
            }
        }, completion: nil)
    }
    
    deinit {
        disposable?.dispose()
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! MovieCell
        cell.setup(movie: movies[indexPath.row])
        return cell
    }

    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return CGSize.zero }
        let collectionViewWidth = self.view.frame.size.width
        if collectionViewWidth > 500 {
            let cellWidth = (collectionViewWidth - collectionViewFlowLayout.minimumInteritemSpacing) / 2
            return CGSize(width:cellWidth, height: 50)
        } else {
            return CGSize(width:collectionViewWidth, height: 50)
        }
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.collectionView?.performBatchUpdates(nil, completion: nil)
    }
}
