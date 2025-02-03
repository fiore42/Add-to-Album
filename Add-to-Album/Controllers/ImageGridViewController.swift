import UIKit
import Photos

class ImageGridViewController: UICollectionViewController {

    private let imageManager = ImageManager()
    private var imageAssets: [PHAsset] = []
    private let imageCache = NSCache<NSNumber, UIImage>()
    private var isLoadingBatch = false

    private let batchSize = 30
    private var flowLayout: UICollectionViewFlowLayout!

    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.log("🟢 ImageGridViewController Loaded")

        setupCollectionView()
        checkPermissions()
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")

        flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        collectionView.setCollectionViewLayout(flowLayout, animated: false)
    }

    private func checkPermissions() {
        imageManager.requestPhotoPermissions { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.loadNextBatch()
                } else {
                    Logger.log("🚫 Permissions Not Granted")
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGridLayout()
    }

    private func updateGridLayout() {
        let spacing: CGFloat = 5
        let columns: CGFloat = 4
        let size = (view.safeAreaLayoutGuide.layoutFrame.width - (columns - 1) * spacing) / columns
        flowLayout.itemSize = CGSize(width: size, height: size)
        flowLayout.invalidateLayout()
    }

    // MARK: - Data Loading

    func loadNextBatch() {
        guard !isLoadingBatch else { return }
        isLoadingBatch = true

        Logger.log("🔄 Loading next batch...")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newAssets = self?.imageManager.fetchNextBatch(batchSize: self?.batchSize ?? 30, after: self?.imageAssets.last) ?? []

            DispatchQueue.main.async {
                self?.isLoadingBatch = false
                if !newAssets.isEmpty {
                    self?.imageAssets.append(contentsOf: newAssets)
                    self?.collectionView.reloadData()
                    Logger.log("✅ Loaded Batch. Total Images: \(self?.imageAssets.count ?? 0)")
                } else {
                    Logger.log("⛔ No More Images to Load.")
                }
            }
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { checkForBatchLoading() }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkForBatchLoading()
    }

    private func checkForBatchLoading() {
        if let lastVisible = collectionView.indexPathsForVisibleItems.max() {
            if lastVisible.item >= imageAssets.count - 5 {
                loadNextBatch()
            }
        }
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
        } else {
            imageManager.requestImage(for: asset, targetSize: targetSize) { [weak self] image in
                DispatchQueue.main.async {
                    if let image = image {
                        cell.imageView.image = image
                        self?.imageCache.setObject(image, forKey: NSNumber(value: asset.hashValue))
                    }
                }
            }
        }

        return cell
    }
}
