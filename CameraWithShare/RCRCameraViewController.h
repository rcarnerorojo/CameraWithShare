//
//  RCRCameraViewController.h
//  CameraWithShare
//
//  Created by Ramón Carnero Rojo on 24/2/15.
//  Copyright (c) 2015 Ramón Carnero Rojo. All rights reserved.
//

@import UIKit;

@interface RCRCameraViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property UIImagePickerController *imagePicker;

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UIView *selectorView;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end
