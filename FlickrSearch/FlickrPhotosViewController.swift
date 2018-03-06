//
//  FlickrPhotosViewController.swift
//  FlickrSearch
//
//  Created by Faisal Alkhotaifi on 3/3/18.
//  Copyright © 2018 Faisal Alkhotaifi. All rights reserved.
//

import UIKit

class FlickrPhotosViewController: UICollectionViewController {    
    
    fileprivate let reuseIdentifier = "FlickrPhotoCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    fileprivate var searches = [FlickrSearchResults]()
    fileprivate let flickr = Flickr()
    fileprivate let itemsPerRow: CGFloat = 3
    
    fileprivate var selectedPhotos = [FlickrPhoto]()
    fileprivate let shareTextLabel = UILabel()
    
    fileprivate let themeColor = (UIApplication.shared.delegate as! AppDelegate).themeColor
    
    var largePhotoIndexPath: NSIndexPath?{
        didSet{
            var indexPaths = [IndexPath]()
            if let largePhotoIndexPath = largePhotoIndexPath{
                indexPaths.append(largePhotoIndexPath as IndexPath)
            }
            if let oldValue = oldValue{
                indexPaths.append(oldValue as IndexPath)
            }
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItems(at: indexPaths)
            }) { completed in
                if let largePhotoIndexPath = self.largePhotoIndexPath{
                    self.collectionView?.scrollToItem(
                        at: largePhotoIndexPath as IndexPath,
                        at: .centeredVertically,
                        animated: true)
                }
            }
        }
    }
    
    var sharing: Bool = false {
        didSet{
            collectionView?.allowsMultipleSelection = sharing
            collectionView?.selectItem(at: nil, animated: true, scrollPosition: UICollectionViewScrollPosition())
            selectedPhotos.removeAll(keepingCapacity: false)
            
            guard let shareButton = self.navigationItem.rightBarButtonItems?.first else {
                return
            }
            
            guard sharing else {
                navigationItem.setRightBarButtonItems([shareButton], animated: true)
                return
            }
            
            if let _ = largePhotoIndexPath{
                largePhotoIndexPath = nil
            }
            
            updateSharedPhotoCount()
            let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
            navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        guard !searches.isEmpty else {
            return
        }
        
        guard !selectedPhotos.isEmpty else {
            sharing = !sharing
            return
        }
        
        guard sharing else {
            return
        }
        
    }
    
}

// MARK: - Private
private extension FlickrPhotosViewController{
    func photoForIndexPath(_ indexPath: IndexPath) -> FlickrPhoto{
        return searches[(indexPath as NSIndexPath).section].searchResults[(indexPath as IndexPath).row]
    }
    
    func updateSharedPhotoCount(){
        shareTextLabel.textColor = themeColor
        shareTextLabel.text = "\(selectedPhotos.count) photos selected"
        shareTextLabel.sizeToFit()
    }
}

// MARK: TextField Delegate
extension FlickrPhotosViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        flickr.searchFlickrForTerm(textField.text!) { (results, error) in
            activityIndicator.removeFromSuperview()
            
            if let error =  error{
                print("Error searching : \(error)")
                return
            }
            if let results = results{
                // The results get logged and added to the front of the searches array
                print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
                self.collectionView?.reloadData()
            }
        }
        
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension FlickrPhotosViewController{
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind{
        case UICollectionElementKindSectionHeader:
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FlickrPhotoHeaderView", for: indexPath) as? FlickrPhotoHeaderView else {
            fatalError("The dequeued header cell is not an instance of FlickrPhotoHeaderView.")
            }
            headerView.label.text = searches[(indexPath as NSIndexPath).section].searchTerm
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            as? FlickrPhotoCell else{
            fatalError("The dequeued cell is not an instance of FlickrPhotoCell.")
        }
        
        let flickrPhoto = photoForIndexPath(indexPath)
        
        guard indexPath == largePhotoIndexPath as IndexPath? else {
            cell.imageView.image = flickrPhoto.thumbnail
            return cell
        }
        
        guard flickrPhoto.largeImage == nil else {
            cell.imageView.image = flickrPhoto.largeImage
            return cell
        }
        
        cell.imageView.image = flickrPhoto.thumbnail
        cell.activityIndicator.startAnimating()
        
        flickrPhoto.loadLargeImage { (loadedFlickrPhoto, error) in
            cell.activityIndicator.stopAnimating()
            
            guard loadedFlickrPhoto.largeImage != nil && error == nil else {
                return
            }
            
            if let cell = collectionView.cellForItem(at: indexPath) as? FlickrPhotoCell, indexPath == self.largePhotoIndexPath as IndexPath?{
                cell.imageView.image = loadedFlickrPhoto.largeImage
            }
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard sharing else{
            return
        }
        
        let photo = photoForIndexPath(indexPath)
        selectedPhotos.append(photo)
        updateSharedPhotoCount()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard sharing else{
            return
        }
        let photo = photoForIndexPath(indexPath)
        if let index = selectedPhotos.index(of: photo) {
            selectedPhotos.remove(at: index)
            updateSharedPhotoCount()
        }
    }
}

// MARK: UICollectionViewDelegate
extension FlickrPhotosViewController{
    //This method is pretty simple. If the tapped cell is already the large photo, set the largePhotoIndexPath property to nil, otherwise set it to the index path the user just tapped. This will then call the property observer you added earlier and cause the collection view to reload the affected cell(s).
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard !sharing else {
            return true
        }
        largePhotoIndexPath = largePhotoIndexPath == indexPath as NSIndexPath ? nil : indexPath as NSIndexPath
        return false
    }
}

// MARK: Collection View Delegate Flow Layout

extension FlickrPhotosViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // New code
        if indexPath == largePhotoIndexPath as IndexPath?{
            let flickrPhoto = photoForIndexPath(indexPath)
            var size = collectionView.bounds.size
            size.height = view.safeAreaLayoutGuide.layoutFrame.height
            size.height -= (sectionInsets.top + sectionInsets.right)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickrPhoto.sizeToFillWidthOfSize(size)
        }
        
        // Old code
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}














