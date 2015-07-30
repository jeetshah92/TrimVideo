//
//  TrimViewController.swift
//  TrimVideo
//
//  Created by Jeet Shah on 6/25/15.
//  Copyright (c) 2015 Jeet Shah. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia
import Foundation

class PTVideoProcessor {
    
    var asset: AVURLAsset?
    var videoWidth: CGFloat?
    var videoHeight: CGFloat?
    var cropOffsetX: CGFloat?
    var cropOffsetY: CGFloat?
    var indicator: UIActivityIndicatorView?
    var offset: NSTimeInterval?
    var framesPerSecond: Int32?
    var initialPlaybackTime: NSTimeInterval?
    var endingPlaybackTime: NSTimeInterval?
    
    
    func cropVideo() {
        
        var clipVideoTrack = asset!.tracksWithMediaType(AVMediaTypeVideo)
        var track = clipVideoTrack[0] as! AVAssetTrack
        var videoComposition = AVMutableVideoComposition(propertiesOfAsset: asset!)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        var resizeWidthFactor = CGFloat(1)
        var resizeHeightFactor = CGFloat(1)
        var cropOffsetX = self.cropOffsetX
        var cropOffsetY = self.cropOffsetY
        var cropWidth = CGFloat(0)
        var cropHeight = CGFloat(0)
        if(videoHeight > videoWidth) {
            
            resizeWidthFactor = track.naturalSize.height / videoWidth!
            resizeHeightFactor = track.naturalSize.width / videoHeight!
            cropWidth = UIScreen.mainScreen().bounds.width * resizeHeightFactor
            cropHeight = UIScreen.mainScreen().bounds.width * resizeHeightFactor
            
        } else if(videoWidth > videoHeight) {
            
            resizeWidthFactor = track.naturalSize.height / videoHeight!
            resizeHeightFactor = track.naturalSize.width / videoWidth!
            cropWidth = UIScreen.mainScreen().bounds.width * resizeWidthFactor
            cropHeight = UIScreen.mainScreen().bounds.width * resizeWidthFactor
            
        } else {
            
            cropWidth = track.naturalSize.width
            cropHeight = track.naturalSize.height
        }
        
        videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight)
        var instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
        var transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack[0] as! AVAssetTrack)
        var t1 = CGAffineTransformIdentity
        var t2 = CGAffineTransformIdentity
        var size = track.naturalSize
        var txf = track.preferredTransform
        
        // check for the video orientation
        if (size.width == txf.tx && size.height == txf.ty) {
            
            //left
            t1 = CGAffineTransformMakeTranslation(track.naturalSize.width - (cropOffsetX! * resizeWidthFactor), track.naturalSize.height - (cropOffsetY! * resizeHeightFactor) )
            t2 = CGAffineTransformRotate(t1, CGFloat(M_PI) )
            
        } else if (txf.tx == 0 && txf.ty == 0) {
            
            //right
        
            t1 = CGAffineTransformMakeTranslation(0 - (cropOffsetX! * resizeWidthFactor), 0 - (cropOffsetY! * resizeHeightFactor))
            t2 = CGAffineTransformRotate(t1, 0)
            
        } else if (txf.tx == 0 && txf.ty == size.width) {
            
            //down
            t1 = CGAffineTransformMakeTranslation(0 - (cropOffsetX! * resizeWidthFactor), track.naturalSize.width - (cropOffsetY! * resizeHeightFactor) )
            t2 = CGAffineTransformRotate(t1, CGFloat(-M_PI_2))
            
        } else {
            
            //up
            t1 = CGAffineTransformMakeTranslation(track.naturalSize.height - (cropOffsetX! * resizeWidthFactor) , 0 - (cropOffsetY! * resizeHeightFactor))
            t2 = CGAffineTransformRotate(t1, CGFloat(M_PI_2))
        }
        
        var finalTransform = t2;
        transformer.setTransform(t2, atTime: kCMTimeZero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        self.trimVideo(videoComposition)
        
    }
    
    func trimVideo(videoComposition: AVMutableVideoComposition) {
        
        let fileManager = NSFileManager.defaultManager()
        let documentsPath : String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as! String
        let destinationPath: String = documentsPath + "/mergeVideo-\(arc4random()%1000).mov"
        let videoPath: NSURL = NSURL(fileURLWithPath: destinationPath as String)!
        let exporter: AVAssetExportSession = AVAssetExportSession(asset: asset!, presetName:AVAssetExportPresetHighestQuality)
        exporter.videoComposition = videoComposition
        exporter.outputURL = videoPath
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(Float64(initialPlaybackTime!), framesPerSecond!), CMTimeMakeWithSeconds(Float64(offset!),framesPerSecond!))
        exporter.exportAsynchronouslyWithCompletionHandler({
            
            dispatch_async(dispatch_get_main_queue(),{
                
                self.exportDidFinish(exporter)
            })
        })
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        
        var outputURL: NSURL = session.outputURL
        var library: ALAssetsLibrary = ALAssetsLibrary()
        if(library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL)) {
            
            library.writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: {(url, error) in
                
                self.indicator!.stopAnimating()
                self.indicator!.removeFromSuperview()
                var alert = UIAlertView(title: "Success", message: "Video Saved Successfully!", delegate: nil, cancelButtonTitle: "Sweet")
                alert.show()
            })
        }
    }
}

class PTFrameWindowControl: UIControl {

    var slider = UIView()
    var sliderMovementConstraint: CGFloat = UIScreen.mainScreen().bounds.width
    var blockedPortion = CALayer()
    var temp: CALayer?
    var framesView = UICollectionView(frame: CGRectZero, collectionViewLayout: PTFrameWindowControl.defaultLayout(CGSize(width: 0, height: 0)))
    var offset: NSTimeInterval = 8
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        
        framesView.frame = bounds
        slider.frame = CGRect(x: sliderMovementConstraint - 10, y: 0, width:10, height: bounds.height)
        blockedPortion.frame = bounds
    }
    
    class func defaultLayout(headerSize: CGSize) -> UICollectionViewFlowLayout {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsZero
        layout.headerReferenceSize = headerSize
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        return layout
    }
    
    func setupViews() {
        
        framesView.backgroundColor = UIColor.clearColor()
        framesView.layer.borderWidth = 1
        framesView.layer.borderColor = UIColor.orangeColor().CGColor
        addSubview(framesView)
        
        slider.backgroundColor = UIColor.whiteColor()
        slider.layer.cornerRadius = 6.0
        var panGesture = UIPanGestureRecognizer(target: self, action: "moveSlider:")
        slider.userInteractionEnabled = true
        slider.addGestureRecognizer(panGesture)
        addSubview(slider)
        
        blockedPortion.backgroundColor = UIColor.clearColor().CGColor
        layer.addSublayer(blockedPortion)
    }
    
    func moveSlider(recognizer: UIPanGestureRecognizer) {
        
        if(recognizer.state == UIGestureRecognizerState.Changed) {
            var translation = recognizer.translationInView(slider)
            var rightConstraint = (recognizer.view!.center.x + translation.x + (recognizer.view!.bounds.width / 2))
            var leftConstraint = (recognizer.view!.center.x + translation.x - (recognizer.view!.bounds.width / 2))

            if(rightConstraint < sliderMovementConstraint && leftConstraint > framesView.frame.origin.y) {
                
                recognizer.view!.center = CGPointMake(recognizer.view!.center.x + translation.x, 0 + (slider.bounds.height) / 2)
                recognizer.setTranslation(CGPointZero, inView: slider)
            }
            
            changeFrameWindow()

        } else if(recognizer.state == UIGestureRecognizerState.Ended) {
            
            sendActionsForControlEvents(UIControlEvents.ValueChanged)
        }
    }
    
    func changeFrameWindow() {
        
        var numOfSelectedFrames = (slider.frame.origin.x / (bounds.width / 8))
        offset = NSTimeInterval(numOfSelectedFrames) 
        if temp != nil {
            
            temp?.removeFromSuperlayer()
        }
        var blockedView = CALayer()
        temp = blockedView
        blockedView.frame = CGRect(x: slider.frame.maxX, y: 0, width: sliderMovementConstraint - slider.frame.maxX, height: bounds.height)
        blockedView.backgroundColor = UIColor(red: 18/255, green: 17/255, blue: 17/255, alpha: 0.5).CGColor
        blockedPortion.addSublayer(blockedView)
    }

}

protocol PTTrimVideoViewDelegate {
    
    func trimVideoView(trimVideoView: PTTrimVideoView?, didPressCancelButton cancelButton: UIButton?)
    func trimVideoView(trimVideoView: PTTrimVideoView?, didPressNextButton nextButton: UIButton?)
    
}

class PTTrimVideoView: UIView, PTTitleBarDelegate {
    
    var titleBar = PTTitleBar()
    var cropLine1 = CALayer()
    var cropLine2 = CALayer()
    var cropLine3 = CALayer()
    var cropLine4 = CALayer()
    var cropLayer = CALayer()
    var mediaPlayer = MPMoviePlayerController()
    var scrollView = UIScrollView()
    var frameWindow = PTFrameWindowControl()
    var trimVideoViewDelegate: PTTrimVideoViewDelegate?

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
        
        scrollView.frame =  CGRect(x: 0, y: titleBar.frame.maxY, width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.width)
        scrollView.contentOffset = CGPointZero
        
        cropLayer.frame =  CGRect(x: 0, y: titleBar.frame.maxY, width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.width)
        cropLine1.frame = CGRect(x: 0, y: cropLayer.bounds.height / 3, width: cropLayer.bounds.width, height: cropLayer.bounds.height * 0.005)
        cropLine2.frame = CGRect(x: 0, y: cropLine1.frame.origin.y + cropLayer.bounds.height / 3, width: cropLayer.bounds.width, height: cropLayer.bounds.height * 0.005)
        cropLine3.frame = CGRect(x: cropLayer.bounds.width / 3, y: 0, width: bounds.width * 0.005, height: cropLayer.bounds.height)
        cropLine4.frame = CGRect(x: cropLine3.frame.origin.x + cropLayer.bounds.width / 3, y: 0, width: bounds.width * 0.005, height: cropLayer.bounds.height)
        
        frameWindow.frame =  CGRect(x: 0, y: scrollView.frame.maxY + 10, width: bounds.width, height: (bounds.height - titleBar.bounds.height - scrollView.bounds.height) * 0.4)
    }

    func setupViews() {
        
        titleBar.backgroundColor = UIColor.blackColor()
        titleBar.nextButton.setTitle("Add", forState: UIControlState.Normal)
        titleBar.cancelButton.setTitle("Back", forState: UIControlState.Normal)
        titleBar.titleLabel.text = "Trim & Crop"
        titleBar.titleLabel.sizeToFit()
        addSubview(titleBar)
    
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(mediaPlayer.view)
        addSubview(scrollView)
        
        cropLine1.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine1)
        cropLine2.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine2)
        cropLine3.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine3)
        cropLine4.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        cropLayer.addSublayer(cropLine4)
        layer.addSublayer(cropLayer)

        frameWindow.backgroundColor = UIColor.clearColor()
        addSubview(frameWindow)
    }
    
    func titleBar(titleBar: PTTitleBar?, didPressCancelButton cancelButton: UIButton?) {
        
        self.trimVideoViewDelegate?.trimVideoView(self, didPressCancelButton: cancelButton)
    }
    
    func titleBar(titleBar: PTTitleBar?, didPressNextButton nextButton: UIButton?) {
        
        self.trimVideoViewDelegate?.trimVideoView(self, didPressNextButton: nextButton)
    }
    
}

protocol TrimViewControllerDelegate {
    
    func trimViewControllerDelegate(trimViewController: TrimViewController?, didPopViewController isPopped: Bool?)
}

class TrimViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PTTrimVideoViewDelegate, UINavigationControllerDelegate {

    
    var trimVideoView = PTTrimVideoView()
    var videoURL = NSURL()
    var videoHeight = CGFloat(0)
    var videoWidth = CGFloat(0)
    var frames = [UIImage]()
    var delegate: TrimViewControllerDelegate?
    var numOfFrames: Int = 0
    var initialPlaybackTime: NSTimeInterval = 0
    var endingPlaybackTime: NSTimeInterval = 8
    var framesPerSecond: Int32 = 0
    var indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    var shouldTrimMovie: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable auto rotation
        var shared = UIApplication.sharedApplication().delegate as! AppDelegate
        shared.blockRotation = true
        
        registerNotifications()
        trimVideoView.frameWindow.framesView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        trimVideoView.frameWindow.framesView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "LoadingCell")
        trimVideoView.frameWindow.addTarget(self, action: "changeMoviePlayBack:", forControlEvents: UIControlEvents.ValueChanged)
        layoutViews()
        fetchFrames()
        trimVideoView.trimVideoViewDelegate = self
        trimVideoView.frameWindow.framesView.dataSource = self
        trimVideoView.frameWindow.framesView.delegate = self
        playMovie(videoURL, initialPlayBackTime: self.initialPlaybackTime, endPlayBackTime: self.endingPlaybackTime)
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func registerNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resumeMoviePlayer:", name: "ApplicationEnteredForeground", object: nil)
    }
    
    func changeMoviePlayBack(frameWindow: PTFrameWindowControl) {
       
        trimMovie()
    }

    func resumeMoviePlayer(notification: NSNotification) {
        
        if (isViewLoaded() && view.window != nil) {
            
            // MPMovieplayer stops when currentplaybacktime is equal to initialplaybacktine
            if(trimVideoView.mediaPlayer.playbackState == MPMoviePlaybackState.Paused && !shouldTrimMovie) {
        
                if( trimVideoView.mediaPlayer.currentPlaybackTime == initialPlaybackTime) {
                    
                    trimVideoView.mediaPlayer.currentPlaybackTime = initialPlaybackTime
    
                }
                trimVideoView.mediaPlayer.play()
               
            } else {
             
                trimMovie()
                shouldTrimMovie = false
            }
        }
    }
    
    func layoutViews() {
        
        trimVideoView.frame = view.frame
        indicator.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        indicator.frame = view.bounds
        view.addSubview(trimVideoView)
    }

    func fetchFrames() {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            var asset = AVURLAsset(URL: self.videoURL, options: nil)
            var movieTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as! AVAssetTrack
            var imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            var maxSize = CGSizeMake(320, 180);
            imageGenerator.maximumSize = maxSize
            var durationInSeconds: Float64 = CMTimeGetSeconds(asset.duration)
            self.framesPerSecond = Int32(movieTrack.nominalFrameRate)
            var timePerFrame = 1.0 / Float64(movieTrack.nominalFrameRate)
            var totalFrames = durationInSeconds * Float64(movieTrack.nominalFrameRate)
            self.numOfFrames = Int(ceil(durationInSeconds))
            
            for var i:Float64 = 0; i < durationInSeconds ; i++ {
                
                var time = CMTimeMakeWithSeconds(i, Int32(movieTrack.nominalFrameRate))
                var image = imageGenerator.copyCGImageAtTime(time, actualTime: nil, error: nil)
                if(image != nil) {
                    
                    self.frames.append(UIImage(CGImage:image!)!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.trimVideoView.frameWindow.framesView.reloadData()
                    })

                }
                
            }
            
        })
        
    }
    
    func trimMovie() {
        
        var indexPathOfVisibleCells = trimVideoView.frameWindow.framesView.indexPathsForVisibleItems()
        indexPathOfVisibleCells.sort({$0.row < $1.row})
        initialPlaybackTime = NSTimeInterval(indexPathOfVisibleCells[0].row)
        endingPlaybackTime = initialPlaybackTime + trimVideoView.frameWindow.offset
        
        trimVideoView.mediaPlayer.stop()
        playMovie(self.videoURL, initialPlayBackTime: self.initialPlaybackTime, endPlayBackTime: self.endingPlaybackTime)
    
    }
    
    func playMovie(url: NSURL, initialPlayBackTime: NSTimeInterval, endPlayBackTime: NSTimeInterval) {
        
        trimVideoView.mediaPlayer.view.removeFromSuperview()
        trimVideoView.mediaPlayer = MPMoviePlayerController()
        trimVideoView.scrollView.contentSize = CGSizeMake(videoWidth, videoHeight)
        trimVideoView.mediaPlayer.view.frame = CGRect(x: 0, y: 0, width:videoWidth, height: videoHeight)
        trimVideoView.mediaPlayer.view.backgroundColor = UIColor.clearColor()
        trimVideoView.scrollView.addSubview(trimVideoView.mediaPlayer.view)
        trimVideoView.mediaPlayer.contentURL = url
        trimVideoView.mediaPlayer.prepareToPlay()
        trimVideoView.mediaPlayer.movieSourceType = MPMovieSourceType.File
        trimVideoView.mediaPlayer.controlStyle = MPMovieControlStyle.None
        trimVideoView.mediaPlayer.repeatMode = MPMovieRepeatMode.One
        trimVideoView.mediaPlayer.scalingMode = MPMovieScalingMode.AspectFit
        trimVideoView.mediaPlayer.initialPlaybackTime = initialPlayBackTime
        trimVideoView.mediaPlayer.endPlaybackTime = endPlayBackTime
        trimVideoView.mediaPlayer.play()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
       if(numOfFrames < 8 && frames.count == numOfFrames) {
        
            trimVideoView.frameWindow.sliderMovementConstraint = CGFloat(numOfFrames) * (collectionView.bounds.width / 8)
            trimVideoView.frameWindow.setNeedsLayout()
        }

        return frames.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as? UICollectionViewCell
        var videoThumbnail =  frames[indexPath.row]
        var sx = cell!.bounds.width / videoThumbnail.size.width
        var sy = cell!.bounds.height / videoThumbnail.size.height
        var cellThumbnail = UIImageView(image:videoThumbnail)
        cellThumbnail.transform = CGAffineTransformScale(cellThumbnail.transform, sx, sy)
        cellThumbnail.frame.origin.x = 0
        cellThumbnail.frame.origin.y = 0
        cell!.addSubview(cellThumbnail)
        return cell!
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let itemSize = CGSize(width: floor(collectionView.bounds.width / 8), height: floor(collectionView.bounds.height))
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // do something
        
    }
    
    func trimVideoView(trimVideoView: PTTrimVideoView?, didPressCancelButton cancelButton: UIButton?) {
        
        if(trimVideoView!.mediaPlayer.playbackState == MPMoviePlaybackState.Playing) {
            
            trimVideoView!.mediaPlayer.stop()
        }
        frames.removeAll(keepCapacity: false)
        delegate?.trimViewControllerDelegate(self, didPopViewController: true)
        navigationController?.popViewControllerAnimated(true)
    }
    
    func trimVideoView(trimVideoView: PTTrimVideoView?, didPressNextButton nextButton: UIButton?) {
        
        self.view.addSubview(self.indicator)
        self.indicator.center = self.view.center
        self.indicator.startAnimating()
        var trimmedVideo = AVURLAsset(URL: videoURL, options: nil)

        var videoProcessor = PTVideoProcessor()
        
        //initialize videoProcessor
        videoProcessor.asset = trimmedVideo
        videoProcessor.videoHeight = videoHeight
        videoProcessor.videoWidth = videoWidth
        videoProcessor.indicator = indicator
        videoProcessor.cropOffsetX = trimVideoView?.scrollView.contentOffset.x
        videoProcessor.cropOffsetY = trimVideoView?.scrollView.contentOffset.y
        videoProcessor.offset =  trimVideoView?.frameWindow.offset
        videoProcessor.initialPlaybackTime = initialPlaybackTime
        videoProcessor.endingPlaybackTime = endingPlaybackTime
        videoProcessor.framesPerSecond = framesPerSecond
        
        //crop and trim video
        videoProcessor.cropVideo()

    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //collectionview still scrolls even after app goes in background
        if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
            
            trimMovie()
            
        } else {
            
            shouldTrimMovie = true
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if(!decelerate) {
           trimMovie()
        }
    }
}
