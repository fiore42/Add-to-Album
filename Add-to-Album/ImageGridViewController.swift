import UIKit
import Photos

class ImageGridViewController: UICollectionViewController {

    private let imageManager = ImageManager()
    private var imageAssets: [PHAsset] = []
    private let imageCache = NSCache<NSNumber, UIImage>()
    private var isLoadingBatch = false

    private var collectionViewFlowLayout: UICollectionViewFlowLayout! // Declare the layout property

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout()) // Initialize with a default layout
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("ImageGridViewController loaded")

        collectionViewFlowLayout = createGridLayout() // Create and assign the layout
        collectionView.collectionViewLayout = collectionViewFlowLayout // Set the collection view's layout

        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")

        imageManager.requestPhotoPermissions { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.loadNextBatch()
                } else {
                    print("Permissions not granted")
                    let alert = UIAlertController(title: "Permission Denied", message: "Please grant access to your photos in Settings.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    private func createGridLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 5
        let numberOfColumns: CGFloat = 4
        let itemSize = (view.frame.width - (numberOfColumns - 1) * spacing) / numberOfColumns
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        return layout
    }

    // MARK: - Data Loading and UIScrollViewDelegate

    func loadNextBatch() {
        guard !isLoadingBatch else { return }

        isLoadingBatch = true
        print("Loading next batch...")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newAssets = self?.imageManager.fetchNextBatch(batchSize: 30, after: self?.imageAssets.last) ?? []

            DispatchQueue.main.async {
                if !newAssets.isEmpty {
                    self?.imageAssets.append(contentsOf: newAssets)
                    self?.collectionView.reloadData()
                    print("Batch loaded. Total images: \(self?.imageAssets.count ?? 0)")
                } else {
                    print("No more images to load.")
                }
                self?.isLoadingBatch = false
            }
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            checkForBatchLoading()
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkForBatchLoading()
    }

    private func checkForBatchLoading() {
        let visibleRect = CGRect(origin: self.collectionView.contentOffset, size: self.collectionView.frame.size)
        let visibleImages = self.collectionView.indexPathsForVisibleItems ?? []

        if !visibleImages.isEmpty {
            let lastIndexPath = visibleImages.max(by: { $0 < $1 })!
            let lastCellRect = self.collectionView.layoutAttributesForItem(at: lastIndexPath)!.frame
            if lastCellRect.maxY <= visibleRect.maxY + 200 {
                loadNextBatch()
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageAssets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell

        let asset = imageAssets[indexPath.item]
        let targetSize = CGSize(width: 200, height: 200)

        if let cachedImage = imageCache.object(forKey: NSNumber(value: asset.hashValue)) {
            cell.imageView.image = cachedImage
            print("Image loaded from cache")
        } else {
            imageManager.requestImage(for: asset, targetSize: targetSize) { [weak self] image in
                DispatchQueue.main.async {
                    if let image = image {
                        cell.imageView.image = image
                        self?.imageCache.setObject(image, forKey: NSNumber(value: asset.hashValue))
                        print("Image loaded from asset")
                    }
                }
            }
        }

        return cell
    }
}

class ImageCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.frame = contentView.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
