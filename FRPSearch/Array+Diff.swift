import Foundation

public extension Array where Element: Equatable {
    public func diffIndexs(other: [Element]) -> ([NSIndexPath],[NSIndexPath]) {
        let diff = self.diff(other)
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
        return (insertedIndexPaths, deletedIndexPaths)
    }
}