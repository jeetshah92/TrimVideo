//
//  ViewController.swift
//  TrimVideo
//
//  Created by Jeet Shah on 6/24/15.
//  Copyright (c) 2015 Jeet Shah. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer

class PTVideoCell: UICollectionViewCell {
    
    var videoThumbnail = UIImageView()
    var videoDuration = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        videoThumbnail.frame = self.bounds
    }
    
    func setupViews() {
        
        addSubview(videoThumbnail)
        
        videoDuration.sizeToFit()
        addSubview(videoDuration)
    }
    
    override var selected: Bool {
        willSet(newValue) {
            println("changing from \(selected) to \(newValue)")
        }
        
        didSet {
            println("selected=\(selected)")
            videoThumbnail.layer.borderWidth = selected ? 2.0 : 0.0
            videoThumbnail.layer.borderColor = UIColor.whiteColor().CGColor
        }
    }

}

protocol PTVideoPickerViewDelegate {
    
    func videoPickerView(videoPickerView: PTVideoPickerView?, didPressNextButton nextButton: UIButton?)
    func videoPickerView(videoPickerView: PTVideoPickerView?, didPressCancelButton cancelButton: UIButton?)
}

class PTVideoPickerView: UIView, PTTitleBarDelegate {

    var titleBar = PTTitleBar()
    var mediaPlayer = MPMoviePlayerController()
    var videoCollection = UICollectionView(frame: CGRectZero, collectionViewLayout: PTVideoPickerView.defaultLayout(CGSize(width: 0, height: 0)))
    var videoPickerViewDelegate: PTVideoPickerViewDelegate?

    class func defaultLayout(headerSize: CGSize) -> UICollectionViewFlowLayout {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsZero
        layout.headerReferenceSize = headerSize
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        return layout
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleBar.titleBarDelegate = self
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        
        titleBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.1)
        
        mediaPlayer.view.frame = CGRect(x: 0, y: titleBar.frame.maxY, width: bounds.width, height: bounds.height * 0.55)
        
        videoCollection.frame =  CGRect(x: 0, y: mediaPlayer.view.frame.maxY + 10, width: bounds.width, height: bounds.height - titleBar.bounds.height - mediaPlayer.view.bounds.height)
    }
    
    func setupViews() {
        
        titleBar.backgroundColor = UIColor.blackColor()
        addSubview(titleBar)
    
        mediaPlayer.movieSourceType = MPMovieSourceType.File
        mediaPlayer.controlStyle = MPMovieControlStyle.None
        mediaPlayer.repeatMode = MPMovieRepeatMode.One
        mediaPlayer.scalingMode = MPMovieScalingMode.AspectFill
        mediaPlayer.view.backgroundColor = UIColor.clearColor()
        addSubview(mediaPlayer.view)
        
        videoCollection.backgroundColor = UIColor.blackColor()
        addSubview(videoCollection)
    }

    func titleBar(titleBar: PTTitleBar?, didPressCancelButton cancelButton: UIButton?) {
        
        videoPickerViewDelegate?.videoPickerView(self, didPressCancelButton: cancelButton)
    }
    
    func titleBar(titleBar: PTTitleBar?, didPressNextButton nextButton: UIButton?) {
        
        videoPickerViewDelegate?.videoPickerView(self, didPressNextButton: nextButton)
    }
    
}

class ViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PTVideoPickerViewDelegate, TrimViewControllerDelegate {

    var trimViewController: TrimViewController?
    var assetLibrary = ALAssetsLibrary()
    var videos = [ALAsset]()
    var videoPickerView = PTVideoPickerView()
    var currentVideoHeight: CGFloat?
    var currentVideoWidth: CGFloat?
    var currentMovieURL: NSURL?
    var shouldPlayFirstVideo: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable auto rotation
        var shared = UIApplication.sharedApplication().delegate as! AppDelegate
        shared.blockRotation = true
        
        registerNotifications()
        videoPickerView.videoCollection.delegate = self
        videoPickerView.videoCollection.dataSource = self
        videoPickerView.videoCollection.registerClass(PTVideoCell.self, forCellWithReuseIdentifier: "Cell")
        videoPickerView.videoPickerViewDelegate = self
        loadVideos()
        layoutView()
    }

    func registerNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resumeMoviePlayer:", name: "ApplicationEnteredForeground", object: nil)
    }
    
    func resumeMoviePlayer(notification: NSNotification) {
        
        if (isViewLoaded() && view.window != nil) {
           
            videoPickerView.mediaPlayer.play()
        }
    }
    
    func layoutView() {
        
        videoPickerView.frame = self.view.frame
        self.view.addSubview(videoPickerView)
    }
    
    func loadVideos() {
        
        assetLibrary.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos, usingBlock: { (grp: ALAssetsGroup!, groupBool: UnsafeMutablePointer<ObjCBool>) -> Void in
            // do something here
            if ALAssetsFilter.allVideos() != nil && grp != nil {
                grp.setAssetsFilter(ALAssetsFilter.allVideos())
                if grp != nil {
                    grp.setAssetsFilter(ALAssetsFilter.allVideos())
                    grp.enumerateAssetsUsingBlock({ (asset: ALAsset?, index: Int, assetBool: UnsafeMutablePointer<ObjCBool>) -> Void in
                        
                        if asset != nil  {
                            
                             self.videos.append(asset!)
                             self.videoPickerView.videoCollection.reloadData()
                            
                        }
                       
                    })
                }
            }
            
        }) { (error) -> Void in
            // Handle error
            println("error in fetching assets")
        }
        
    }
            
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func convertCfTypeToCGImage(cgValue: Unmanaged<CGImage>) -> CGImage{
        
        let value = Unmanaged.fromOpaque(
            cgValue.toOpaque()).takeUnretainedValue() as CGImage
        return value
    }
    
    func playMovie(url: NSURL) {

        videoPickerView.mediaPlayer.contentURL = url
        videoPickerView.mediaPlayer.prepareToPlay()
        videoPickerView.mediaPlayer.play()
    }
    
    // Implement CollectionView Delegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return videos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! PTVideoCell
        cell.backgroundColor = UIColor.blackColor()
        
        //set movie thumbnail
        var managedCGImage = convertCfTypeToCGImage(videos[indexPath.row].thumbnail())
        var videoThumbnail: UIImage = UIImage(CGImage: managedCGImage)!
        var sx = cell.bounds.width / videoThumbnail.size.width
        var sy = cell.bounds.height / videoThumbnail.size.height
        cell.videoThumbnail.image = videoThumbnail
        cell.videoThumbnail.transform = CGAffineTransformScale(cell.videoThumbnail.transform, sx, sy)
        cell.videoThumbnail.frame.origin.x = 0
        cell.videoThumbnail.frame.origin.y = 0

        var duration: AnyObject! = videos[indexPath.row].valueForProperty(ALAssetPropertyDuration)
        var seconds = duration as! Int % 60;
        var minutes = (duration as! Int / 60) % 60;
        var hours = duration as! Int / 3600;
        
        //display duration of movie
        var formattedDuration: String = "\(hours):\(minutes):\(seconds)"
        cell.videoDuration.text = formattedDuration
        cell.videoDuration.sizeToFit()
        cell.videoDuration.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        cell.videoDuration.frame = CGRect(x: (cell.frame.width -  cell.videoDuration.frame.width) / 2.0, y: (cell.frame.height -  cell.videoDuration.frame.height) / 2.0, width:  cell.videoDuration.frame.width, height:  cell.videoDuration.frame.height)
        
        if(shouldPlayFirstVideo == true && indexPath.row == 1) {
            
            self.collectionView(collectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
            shouldPlayFirstVideo = false
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let itemSize = CGSize(width: floor((collectionView.bounds.width - 30) / 4), height: floor((collectionView.bounds.width - 30) / 4))
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if(videoPickerView.mediaPlayer.playbackState == MPMoviePlaybackState.Playing) {
            
            videoPickerView.mediaPlayer.stop()
        }
        
        var videoRepresentation = videos[indexPath.row].defaultRepresentation()
        var path = videoRepresentation.url()
        
        var videoWidth = videoRepresentation.dimensions().width
        var videoHeight = videoRepresentation.dimensions().height
        var aspectRatio = videoWidth / videoHeight
        
        // check for Portrait mode or Landscape mode
        if(videoHeight > videoWidth) {
            
            println("portrait mode")
            var resizeHeight = round((UIScreen.mainScreen().bounds.width) / aspectRatio)
            currentVideoHeight = resizeHeight
            currentVideoWidth = UIScreen.mainScreen().bounds.width
            
        } else if(videoHeight < videoWidth) {
            
            println("Landscape mode")
            var resizeWidth = round((UIScreen.mainScreen().bounds.width) * aspectRatio)
            currentVideoHeight = UIScreen.mainScreen().bounds.width
            currentVideoWidth = resizeWidth
            
        } else {
            
            println("equal width and height")
            currentVideoHeight = UIScreen.mainScreen().bounds.width
            currentVideoWidth = UIScreen.mainScreen().bounds.width
        }
        
        currentMovieURL = path
        playMovie(path)
    }
   
   //Implement VideoPickerView Delegate
    func videoPickerView(videoPickerView: PTVideoPickerView?, didPressCancelButton cancelButton: UIButton?){
        
        println("cancel button pressed")

    }
    
    func videoPickerView(videoPickerView: PTVideoPickerView?, didPressNextButton nextButton: UIButton?) {
        
        if(videoPickerView!.mediaPlayer.playbackState == MPMoviePlaybackState.Playing) {
            
            videoPickerView!.mediaPlayer.stop()
        }

        trimViewController = TrimViewController()
        trimViewController!.videoURL = self.currentMovieURL!
        trimViewController!.delegate = self
        trimViewController!.videoWidth = currentVideoWidth!
        trimViewController!.videoHeight = currentVideoHeight!
        navigationController?.pushViewController(self.trimViewController!, animated: false)
    }
    
    //Implement TrimViewControllerDelegate
    func trimViewControllerDelegate(trimViewController: TrimViewController?, didPopViewController isPopped: Bool?) {
        
          videoPickerView.mediaPlayer.play()

    }
    
}


