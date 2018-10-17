//
//  SwiftyGiphyViewController.swift
//  SwiftyGiphy
//
//  Created by Brendan Lee on 3/9/17.
//  Copyright © 2017 52inc. All rights reserved.
//

import UIKit
import AVFoundation
import NSTimer_Blocks

public protocol SwiftyGiphyViewControllerDelegate: class {

    func giphyControllerDidSelectGif(controller: SwiftyGiphyViewController, item: GiphyItem)
    func giphyControllerDidCancel(controller: SwiftyGiphyViewController)
}

fileprivate let kSwiftyGiphyCollectionViewCell = "SwiftyGiphyCollectionViewCell"

public class SwiftyGiphyViewController: UIViewController {

    fileprivate let searchController: UISearchController = UISearchController(searchResultsController: nil)
    fileprivate let searchContainerView: UIView = UIView(frame: CGRect.zero)

    fileprivate let collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: SwiftyGiphyGridLayout())

    fileprivate let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)

    fileprivate let errorLabel: UILabel = UILabel()

    fileprivate var latestTrendingResponse: GiphyMultipleGIFResponse?
    fileprivate var latestSearchResponse: GiphyMultipleGIFResponse?

    fileprivate var combinedTrendingGifs: [GiphyItem] = [GiphyItem]()
    fileprivate var combinedSearchGifs: [GiphyItem] = [GiphyItem]()

    fileprivate var currentGifs: [GiphyItem]? {
        didSet {
            collectionView.reloadData()
        }
    }

    fileprivate var currentTrendingPageOffset: Int = 0
    fileprivate var currentSearchPageOffset: Int = 0

    fileprivate var searchCounter: Int = 0

    fileprivate var isTrendingPageLoadInProgress: Bool = false
    fileprivate var isSearchPageLoadInProgress: Bool = false

    fileprivate var keyboardAdjustConstraint: NSLayoutConstraint!

    fileprivate var searchCoalesceTimer: Timer? {
        willSet {
            if searchCoalesceTimer?.isValid == true
            {
                searchCoalesceTimer?.invalidate()
            }
        }
    }

    /// The maximum content rating allowed for the shown gifs
    public var contentRating: SwiftyGiphyAPIContentRating = .pg13

    /// The maximum allowed size for gifs shown in the feed
    public var maxSizeInBytes: Int = 2048000 // 2MB size cap by default. We're on mobile, after all.

    /// Allow paging the API results. Enabled by default, but you can disable it if you use a custom base URL that doesn't support it.
    public var allowResultPaging: Bool = true

    /// The collection view layout that governs the waterfall layout of the gifs. There are a few parameters you can modify, but we recommend the defaults.
    public var collectionViewLayout: SwiftyGiphyGridLayout? {
        get {
            return collectionView.collectionViewLayout as? SwiftyGiphyGridLayout
        }
    }

    /// The object to receive callbacks for when the user cancels or selects a gif. It is the delegate's responsibility to dismiss the SwiftyGiphyViewController.
    public weak var delegate: SwiftyGiphyViewControllerDelegate?

    public override func loadView() {
        super.loadView()

        self.title = NSLocalizedString("Giphy", comment: "Giphy")
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "GiphyLogoEmblem", in: Bundle(for: SwiftyGiphyViewController.self), compatibleWith: nil))

        searchController.searchBar.placeholder = NSLocalizedString("Search GIFs", comment: "The placeholder string for the Giphy search field")
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.delegate = self

        searchContainerView.backgroundColor = UIColor.clear
        searchContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.addSubview(searchController.searchBar)

        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.keyboardDismissMode = .interactive

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        loadingIndicator.color = UIColor.lightGray
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        errorLabel.textAlignment = .center
        errorLabel.textColor = UIColor.lightGray
        errorLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.isHidden = true

        self.view.addSubview(collectionView)
        self.view.addSubview(loadingIndicator)
        self.view.addSubview(errorLabel)
        self.view.addSubview(searchContainerView)

        keyboardAdjustConstraint = collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([
                searchContainerView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                searchContainerView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
                searchContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                searchContainerView.heightAnchor.constraint(equalToConstant: 44.0),
                collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
                collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                keyboardAdjustConstraint
            ])

        NSLayoutConstraint.activate([
                loadingIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor, constant: 0.0),
                loadingIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: 32.0)
            ])

        NSLayoutConstraint.activate([
                errorLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30.0),
                errorLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30.0),
                errorLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: 32.0)
            ])

        collectionView.register(SwiftyGiphyCollectionViewCell.self, forCellWithReuseIdentifier: kSwiftyGiphyCollectionViewCell)

        self.view.backgroundColor = UIColor.groupTableViewBackground
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let collectionViewLayout = collectionView.collectionViewLayout as? SwiftyGiphyGridLayout
        {
            collectionViewLayout.delegate = self
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateBottomLayoutConstraintWithNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        fetchNextTrendingDataPage()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        if self.navigationController?.viewControllers.count == 1 && self.navigationController?.presentingViewController != nil
        {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPicker))
        }
        else
        {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if #available(iOS 11, *)
        {
            collectionView.contentInset = UIEdgeInsets.init(top: 44.0, left: 0.0, bottom: 10.0, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets.init(top: 44.0, left: 0.0, bottom: 10.0, right: 0.0)
        }
        else
        {
            collectionView.contentInset = UIEdgeInsets.init(top: self.topLayoutGuide.length + 44.0, left: 0.0, bottom: 10.0, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets.init(top: self.topLayoutGuide.length + 44.0, left: 0.0, bottom: 10.0, right: 0.0)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        searchController.searchBar.frame = searchContainerView.bounds
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc fileprivate func dismissPicker()
    {
        searchController.isActive = false
        delegate?.giphyControllerDidCancel(controller: self)
    }

    fileprivate func fetchNextTrendingDataPage()
    {
        guard !isTrendingPageLoadInProgress else {
            return
        }

        if currentGifs?.count ?? 0 == 0
        {
            loadingIndicator.startAnimating()
            errorLabel.isHidden = true
        }

        isTrendingPageLoadInProgress = true

        let maxBytes = maxSizeInBytes
        let width = max((collectionView.collectionViewLayout as? SwiftyGiphyGridLayout)?.columnWidth ?? 0.0, 0.0)

        SwiftyGiphyAPI.shared.getTrending(limit: 100, rating: contentRating, offset: currentTrendingPageOffset) { [weak self] (error, response) in

            self?.isTrendingPageLoadInProgress = false
            self?.loadingIndicator.stopAnimating()
            self?.errorLabel.isHidden = true

            guard error == nil else {

                if self?.currentGifs?.count ?? 0 == 0
                {
                    self?.errorLabel.text = error?.localizedDescription
                    self?.errorLabel.isHidden = false
                }

                print("Giphy error: \(String(describing: error?.localizedDescription))")
                return
            }

            self?.latestTrendingResponse = response
            self?.combinedTrendingGifs.append(contentsOf: response!.gifsSmallerThan(sizeInBytes: maxBytes, forWidth: width))
            self?.currentTrendingPageOffset = (response!.pagination?.offset ?? (self?.currentTrendingPageOffset ?? 0)) + (response!.pagination?.count ?? 0)

            self?.currentGifs = self?.combinedTrendingGifs

            self?.collectionView.reloadData()
        }
    }

    fileprivate func fetchNextSearchPage()
    {
        guard !isSearchPageLoadInProgress else {
            return
        }

        guard let searchText = searchController.searchBar.text, searchText.count > 0 else {

            self.searchCounter += 1
            self.currentGifs = combinedTrendingGifs
            return
        }

        searchCoalesceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, block: { [unowned self] () -> Void in

            self.isSearchPageLoadInProgress = true

            if self.currentGifs?.count ?? 0 == 0
            {
                self.loadingIndicator.startAnimating()
                self.errorLabel.isHidden = true
            }

            self.searchCounter += 1

            let currentCounter = self.searchCounter

            let maxBytes = self.maxSizeInBytes
            let width = max((self.collectionView.collectionViewLayout as? SwiftyGiphyGridLayout)?.columnWidth ?? 0.0, 0.0)

            SwiftyGiphyAPI.shared.getSearch(searchTerm: searchText, limit: 100, rating: self.contentRating, offset: self.currentSearchPageOffset) { [weak self] (error, response) in

                self?.isSearchPageLoadInProgress = false

                guard currentCounter == self?.searchCounter else {

                    return
                }

                self?.loadingIndicator.stopAnimating()
                self?.errorLabel.isHidden = true

                guard error == nil else {

                    if self?.currentGifs?.count ?? 0 == 0
                    {
                        self?.errorLabel.text = error?.localizedDescription
                        self?.errorLabel.isHidden = false
                    }

                    print("Giphy error: \(String(describing: error?.localizedDescription))")
                    return
                }

                self?.latestSearchResponse = response
                self?.combinedSearchGifs.append(contentsOf: response!.gifsSmallerThan(sizeInBytes: maxBytes, forWidth: width))
                self?.currentSearchPageOffset = (response!.pagination?.offset ?? (self?.currentSearchPageOffset ?? 0)) + (response!.pagination?.count ?? 0)

                self?.currentGifs = self?.combinedSearchGifs

                self?.collectionView.reloadData()

                if self?.currentGifs?.count ?? 0 == 0
                {
                    self?.errorLabel.text = NSLocalizedString("No GIFs match this search.", comment: "No GIFs match this search.")
                    self?.errorLabel.isHidden = false
                }
            }
        }, repeats: false) as! Timer?
    }
}

// MARK: - SwiftyGiphyGridLayoutDelegate
extension SwiftyGiphyViewController: SwiftyGiphyGridLayoutDelegate {

    public func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath, withWidth: CGFloat) -> CGFloat
    {
        guard let imageSet = currentGifs?[indexPath.row].imageSetClosestTo(width: withWidth, animated: true) else {
            return 0.0
        }

        return AVMakeRect(aspectRatio: CGSize(width: imageSet.width, height: imageSet.height), insideRect: CGRect(x: 0.0, y: 0.0, width: withWidth, height: CGFloat.greatestFiniteMagnitude)).height
    }
}

// MARK: - UICollectionViewDataSource
extension SwiftyGiphyViewController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return currentGifs?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kSwiftyGiphyCollectionViewCell, for: indexPath) as! SwiftyGiphyCollectionViewCell

        if let collectionViewLayout = collectionView.collectionViewLayout as? SwiftyGiphyGridLayout, let imageSet = currentGifs?[indexPath.row].imageSetClosestTo(width: collectionViewLayout.columnWidth, animated: true)
        {
            cell.configureFor(imageSet: imageSet)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SwiftyGiphyViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        let selectedGif = currentGifs![indexPath.row]

        searchController.isActive = false
        delegate?.giphyControllerDidSelectGif(controller: self, item: selectedGif)
    }
}

// MARK: - UISearchControllerDelegate
extension SwiftyGiphyViewController: UISearchControllerDelegate {

    public func willPresentSearchController(_ searchController: UISearchController) {

        searchCounter += 1
        latestSearchResponse = nil
        currentSearchPageOffset = 0
        combinedSearchGifs = [GiphyItem]()
        currentGifs = [GiphyItem]()

        errorLabel.isHidden = true
        loadingIndicator.stopAnimating()
    }

    public func willDismissSearchController(_ searchController: UISearchController) {

        searchController.searchBar.text = nil

        searchCounter += 1
        latestSearchResponse = nil
        currentSearchPageOffset = 0
        combinedSearchGifs = [GiphyItem]()

        currentGifs = combinedTrendingGifs
        collectionView.setContentOffset(CGPoint(x: 0.0, y: -collectionView.contentInset.top), animated: false)

        errorLabel.isHidden = true
        loadingIndicator.stopAnimating()
    }
}

// MARK: - UISearchResultsUpdating
extension SwiftyGiphyViewController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {

        // Destroy current results
        searchCounter += 1
        latestSearchResponse = nil
        currentSearchPageOffset = 0
        combinedSearchGifs = [GiphyItem]()
        currentGifs = [GiphyItem]()
        fetchNextSearchPage()
    }
}

// MARK: - UIScrollViewDelegate
extension SwiftyGiphyViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        guard allowResultPaging else {
            return
        }

        if scrollView.contentOffset.y + scrollView.bounds.height + 100 >= scrollView.contentSize.height
        {
            if searchController.isActive
            {
                if !isSearchPageLoadInProgress && latestSearchResponse != nil
                {
                    // Load next search page
                    fetchNextSearchPage()
                }
            }
            else
            {
                if !isTrendingPageLoadInProgress && latestTrendingResponse != nil
                {
                    // Load next trending page
                    fetchNextTrendingDataPage()
                }
            }
        }
    }
}

// MARK: - Keyboard
extension SwiftyGiphyViewController {

    @objc fileprivate func updateBottomLayoutConstraintWithNotification(notification: NSNotification?) {

        let constantAdjustment: CGFloat = 0.0

        guard let bottomLayoutConstraint: NSLayoutConstraint = keyboardAdjustConstraint else {
            return
        }

        guard let userInfo = notification?.userInfo else {

            bottomLayoutConstraint.constant = constantAdjustment
            return
        }

        let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
        let rawAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value << 16
        let animationCurve = UIView.AnimationOptions(rawValue: UInt(rawAnimationCurve))

        let newConstantValue: CGFloat = max(self.view.bounds.maxY - convertedKeyboardEndFrame.minY + constantAdjustment, 0.0)

        if abs(bottomLayoutConstraint.constant - newConstantValue) >= 1.0
        {
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: animationCurve, animations: {

                bottomLayoutConstraint.constant = -newConstantValue
                self.view.layoutIfNeeded()

            }, completion: nil)
        }
        else
        {
            bottomLayoutConstraint.constant = -newConstantValue
        }
    }
}
