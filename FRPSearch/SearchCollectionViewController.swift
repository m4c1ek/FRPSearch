import UIKit
import RxSwift
import Dwifft

class SearchCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var searchBar: UISearchBar!
    
    var movies:[Movie] = []
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupFetchingMovies()
    }
    
    private func setupFetchingMovies() {
        let moviesObservable = searchBar.rx_text
            .debounce(0.3, scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .UserInitiated) )
            .flatMapLatest(moviesSearchObservable)
            .share()
        
        Observable.zip(moviesObservable, [Observable.just(movies), moviesObservable].concat()) { $0 }
            .observeOn(MainScheduler.instance)
            .subscribeNext({ [weak self] (currentMovies, previousMovies) -> Void in
                self?.updateMovies(currentMovies:currentMovies,previousMovies:previousMovies)
                })
            .addDisposableTo(disposeBag)
    }
    
    private func moviesSearchObservable(text:String?) -> Observable<[Movie]> {
        startedFetchingMovies()
        return MovieObservables.network(searchText: text)
            .doOn(finishedFetchingMovies)
            .catchError({ (error) -> Observable<[Movie]> in
                return Observable.just([])
            })
    }
}

// MARK: Side effects
extension SearchCollectionViewController {
    
    private func updateMovies(currentMovies currentMovies:[Movie], previousMovies:[Movie]) {
        let (deletedIndexPaths, insertedIndexPaths) = currentMovies.diffIndexs(previousMovies)
        self.collectionView?.performBatchUpdates({ () -> Void in
            self.collectionView?.deleteItemsAtIndexPaths(deletedIndexPaths)
            self.collectionView?.insertItemsAtIndexPaths(insertedIndexPaths)
            }, completion: nil)
    }
    
    private func startedFetchingMovies() {
        showNetworkActivity()
        hideError()
    }
    
    private func finishedFetchingMovies(event:Event<[Movie]>) {
        switch event {
        case .Next(let movies):
            self.movies = movies
            stopShowingNetworkActivity()
        case .Error(let error):
            print(error)
            self.movies = []
            stopShowingNetworkActivity()
            showError(error)
        default: ()
        }
    }
    
    private func stopShowingNetworkActivity() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    private func showNetworkActivity() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        })
    }
    
    private func hideError() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            self.collectionView?.backgroundView = nil
        })
    }
    
    private func showError(error: ErrorType) {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            let errorLabel = UILabel(frame: self.collectionView!.frame)
            errorLabel.textAlignment = .Center
            errorLabel.text = "An error occured \(error)"
            self.collectionView?.backgroundView = errorLabel
        })
    }
}

// MARK: UICollectionViewDataSource
extension SearchCollectionViewController {
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MovieCell.cellReuseIdentifier, forIndexPath: indexPath) as! MovieCell
        cell.setup(movie: movies[indexPath.row])
        return cell
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension SearchCollectionViewController {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        guard let collectionViewFlowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return CGSize.zero }
        let collectionViewWidth = self.view.frame.size.width
        let collectionViewColumns = floor(collectionViewWidth / 500) + 1
        let spacing = collectionViewFlowLayout.minimumInteritemSpacing * (collectionViewColumns - 1)
        let cellWidth = (collectionViewWidth - spacing) / collectionViewColumns
        return CGSize(width:cellWidth, height: MovieCell.cellHeight)
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.collectionView?.performBatchUpdates(nil, completion: nil)
    }
}
