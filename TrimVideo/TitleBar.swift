//
//  TitleBar.swift
//  TrimVideo
//
//  Created by Jeet Shah on 6/26/15.
//  Copyright (c) 2015 Jeet Shah. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia

protocol PTTitleBarDelegate {
    
    func titleBar(titleBar: PTTitleBar?, didPressNextButton nextButton: UIButton?)
    func titleBar(titleBar: PTTitleBar?, didPressCancelButton cancelButton: UIButton?)
    
}

class PTTitleBar : UIView {
    
    var cancelButton = UIButton()
    var titleLabel = UILabel()
    var nextButton = UIButton()
    var titleBarDelegate: PTTitleBarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        cancelButton.frame = CGRect(x: 10, y: (bounds.height - (bounds.height * 0.8)) / 2.0, width: bounds.width * 0.2, height: bounds.height * 0.8)
        
        nextButton.frame = CGRect(x: frame.maxX - cancelButton.bounds.width, y: cancelButton.frame.origin.y, width: cancelButton.bounds.width, height: cancelButton.bounds.height)
        
        var x = (bounds.width - cancelButton.bounds.width - nextButton.bounds.width - titleLabel.bounds.width) / 2.0 + cancelButton.frame.maxX
        titleLabel.frame = CGRect(x: x, y: (bounds.height - titleLabel.frame.height) / 2.0, width: titleLabel.frame.width, height: titleLabel.frame.height)
        
    }
    
    func setupViews() {
        
        cancelButton.setTitle("cancel", forState: UIControlState.Normal)
        cancelButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: "didPressCancelButton:", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(cancelButton)
        
        titleLabel.text = "Select Video"
        titleLabel.sizeToFit()
        titleLabel.textColor = UIColor.whiteColor()
        self.addSubview(titleLabel)
        
        nextButton.setTitle(">", forState: UIControlState.Normal)
        nextButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        nextButton.addTarget(self, action: "didPressNextButton:", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(nextButton)
        
        
    }
    
    func didPressCancelButton(button: UIButton) {
        
        self.titleBarDelegate?.titleBar(self, didPressCancelButton: cancelButton)
    }
    
    func didPressNextButton(button: UIButton) {
        
        self.titleBarDelegate?.titleBar(self, didPressNextButton: nextButton)
    }
    
}

