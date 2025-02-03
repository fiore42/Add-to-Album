import UIKit
import Photos

class ViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    
    private var allAssets: PHFetchResult<PHAsset>?
    private let imageManager = PHCachingImageManager()
    private var displayedAssets: [PHAsset] = []
    
    private let batchSize = 30
    private let cellId = "PhotoCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo Grid"
        view.backgroundColor = .systemBackground
        
        checkPermissions()
        setupCollectionView()
    }
    
    private func checkPermissions() {
        let status = PhotoPermissionManager.currentStatus()
        switch status {
        case .granted, .limited:
            log("Access granted/limited. Fetching assets.")
            fetchAssets()
        case .notDetermined:
            log("Access not determined. Requesting...")
            PhotoPermissionManager.requestPermission { [weak self] newStatus in
                self?.log("User chose: \(newStatus)")
                switch newStatus {
                case .granted, .limited:
                    self?.fetchAssets()
                default:
                    self?.showPermissionAlert()
                }
            }
        case .denied, .restricted:
            log("Access denied or restricted.")
            showPermissionAlert()
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Photo Access Needed",
            message: "Please grant access in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    private func fetchAssets() {
        log("Fetching assets...")
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allAssets = PHAsset.fetchAssets(with: .image, options: options)
        
        loadNextBatch()
    }
    
    private func loadNextBatch() {
        guard let allAssets = allAssets else { return }
        
        if displayedAssets.count >= allAssets.count {
            log("All assets loaded.")
            return
        }
        
        let start = displayedAssets.count
        let end = min(start + batchSize, allAssets.count)
        
        var newBatch: [PHAsset] = []
        for i in start..<end {
            newBatch.append(allAssets.object(at: i))
        }
        
        displayedAssets.append(contentsOf: newBatch)
        
        DispatchQueue.main.async {
            self.log("Loaded \(newBatch.count) new assets; total: \(self.displayedAssets.count).")
            self.collectionView.reloadData()
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func log(_ msg: String) {
        print("[\(Date())] \(msg)")
    }
}

// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        displayedAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId,
                                                          for: indexPath) as? PhotoCell
        else {
            fatalError("Could not dequeue PhotoCell")
        }
        
        let asset = displayedAssets[indexPath.item]
        let targetSize = CGSize(width: 120, height: 120)
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset,
                                  targetSize: targetSize,
                                  contentMode: .aspectFill,
                                  options: options) { [weak cell] image, _ in
            cell?.imageView.image = image
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let columns: CGFloat = 3
        let spacing: CGFloat = 2
        let totalSpacing = (columns - 1) * spacing
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / columns)
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - frameHeight - 200 {
            loadNextBatch()
        }
    }
}
