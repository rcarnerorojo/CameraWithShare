//
//  RCRCameraViewController.m
//  CameraWithShare
//
//  Created by Ramón Carnero Rojo on 24/2/15.
//  Copyright (c) 2015 Ramón Carnero Rojo. All rights reserved.
//

#define albumName @"CameraWithShare"

#import "RCRCameraViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
@import AssetsLibrary;

@interface RCRCameraViewController ()
@property BOOL cameraCaptureModeVideo;
@property (strong, nonatomic) UIImage* photo;
@property (strong, nonatomic) ALAssetsLibrary *library;
@property (strong, nonatomic) ALAssetsGroup *groupToAddTo;
@end

@implementation RCRCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cameraCaptureModeVideo = YES;

    //AssetsLibrary para agrupar las fotos y vídeos en un album propio
    self.library = [[ALAssetsLibrary alloc] init];
    
    [self.library addAssetsGroupAlbumWithName:albumName
                             resultBlock:^(ALAssetsGroup *group) {
                                 NSLog(@"added album:%@", albumName);
                             }
                            failureBlock:^(NSError *error) {
                                NSLog(@"error adding album");
                            }];
    
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                   NSLog(@"found album %@", albumName);
                                   self.groupToAddTo = group;
                               }
                           }
                         failureBlock:^(NSError* error) {
                             NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                         }];
    
    
//    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(139, 270, 37, 37)];
//    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
//    [self.imagePicker.view addSubview:self.activityIndicator];
//    self.activityIndicator.hidden = YES;
//    [self.activityIndicator stopAnimating];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self presentViewController:self.imagePicker animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.cameraCaptureModeVideo?[self createImagePickerRecord]:[self createImagePickerPhoto];
    self.imagePicker.cameraOverlayView = self.overlayView;
    
    UISwipeGestureRecognizer *selectGestureRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCameraType:)];
    [selectGestureRecognizerRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.overlayView addGestureRecognizer:selectGestureRecognizerRight];
    
    UISwipeGestureRecognizer *selectGestureRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCameraType:)];
    [selectGestureRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.overlayView addGestureRecognizer:selectGestureRecognizerLeft];
}

- (void) createImagePickerRecord {
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
    self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;

    self.imagePicker.allowsEditing = NO;
    self.imagePicker.showsCameraControls = YES;
    
    int maxSeconds = 30;
    self.imagePicker.videoMaximumDuration = maxSeconds;
    
    // not all devices have two cameras or a flash so just check here
    if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceRear] ) {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    
    if ( [UIImagePickerController isFlashAvailableForCameraDevice:self.imagePicker.cameraDevice] ) {
        self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    }
    
    self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    
    //Podemos cubrir todo el picker, desactivar los controles propios del picker y crear nuestro propios botones
    //CGRect theRect = [self.imagePicker.view frame];
    //En este ejemplo sólo queremos añadir un indicador del tipo de cámara
    CGRect rect = CGRectMake(0, 0, 320, 500);
    [self.overlayView setFrame:rect];
}

-(void) createImagePickerPhoto{
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    CGRect rect = CGRectMake(0, 0, 320, 470);
    [self.overlayView setFrame:rect];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {


    if (self.cameraCaptureModeVideo){
        
        NSURL *videoURL = [info valueForKey:UIImagePickerControllerMediaURL];
        NSString *pathToVideo = [videoURL path];
        
        BOOL okToSaveVideo = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToVideo);
        
        if (okToSaveVideo) {
            
            [self.library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error.code == 0) {
                    NSLog(@"saved image completed:\nurl: %@ \nvideoURL: %@", assetURL, videoURL);
                    
                    // try to get the asset
                    [self.library assetForURL:assetURL
                                  resultBlock:^(ALAsset *asset) {
                                      // assign the photo to the album
                                      [self.groupToAddTo addAsset:asset];
                                      NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                                      
                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Video Guardado" message:@"Almacenado en el carrete" preferredStyle:UIAlertControllerStyleAlert];
                                      
                                      UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                            handler:^(UIAlertAction * action) {[self share:videoURL];}];
                                      [alert addAction:defaultAction];
                                      [self.imagePicker presentViewController:alert animated:NO completion:NULL];
                                      
                                  }
                                 failureBlock:^(NSError* error) {
                                     NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                 }];
                }
                else {
                    NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
                    //Deprecated
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Guardado incorrecto"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
                    [alert show];
                }
            }];
            
            
        }
    }else{
        
        UIImage *photo = [info valueForKey:UIImagePickerControllerOriginalImage];
        self.photo = photo;
        
        CGImageRef img = [photo CGImage];
        [self.library writeImageToSavedPhotosAlbum:img
                                          metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                   completionBlock:^(NSURL* assetURL, NSError* error) {
                                       if (error.code == 0) {
                                           NSLog(@"saved image completed:\nurl: %@", assetURL);
                                           
                                           // try to get the asset
                                           [self.library assetForURL:assetURL
                                                         resultBlock:^(ALAsset *asset) {
                                                             // assign the photo to the album
                                                             [self.groupToAddTo addAsset:asset];
                                                             NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                                                             
                                                             UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Foto Guardada" message:@"Almacenada en el carrete" preferredStyle:UIAlertControllerStyleAlert];
                                                             
                                                             UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                                   handler:^(UIAlertAction * action) {[self share:self.photo];}];
                                                             
                                                             [alert addAction:defaultAction];
                                                             [self.imagePicker presentViewController:alert animated:NO completion:NULL];
                                                             
                                                         }
                                                        failureBlock:^(NSError* error) {
                                                            NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                        }];
                                       }
                                       else {
                                           NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
                                           
                                           //Deprecated
                                           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Guardado incorrecto"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
                                           [alert show];
                                           
                                       }
                                   }];
        
    }
    
    [self dismissViewControllerAnimated:NO completion:NULL];
}

- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    [self dismissViewControllerAnimated:NO completion:^{}];
}

//Hay que tener mucho cuidado con la jerarquía de vistas. Tengo que mostrar el AlertControl encima del picker. Si lo presento en la view, estaré presentándolo detrás del picker. El sistema eliminará datos del AlertControl para ahorrar memoria, fallando.

#pragma mark - ActivityViewController

- (void)share:(id)data {
    
    //Utilizando ActivityController a pelo comparte vídeo por Message, Mail, Fotos de iCloud, Facebook, Google+, Evernote, Telegram. No twitter (esperemos que ahora añadan el comportamiento)
    if(data != nil)
    {
        NSArray *activityItems = @[data];
        NSArray *excludeActivities = @[UIActivityTypeMessage,
                                       UIActivityTypeMail,
                                       UIActivityTypeCopyToPasteboard,
                                       UIActivityTypeAirDrop,
                                       UIActivityTypePrint,
                                       UIActivityTypeAssignToContact,
                                       UIActivityTypeSaveToCameraRoll,
                                       UIActivityTypeAddToReadingList,
                                       UIActivityTypePostToFlickr];
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        
        activityVC.excludedActivityTypes = excludeActivities;
        
        [self.imagePicker presentViewController:activityVC
                           animated:YES
                         completion:^(){
//                             [self.activityIndicator startAnimating];
//                             self.activityIndicator.hidden = NO;
                         }];
        
        [activityVC setCompletionWithItemsHandler:
         ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
//             [self.activityIndicator stopAnimating];
//             self.activityIndicator.hidden = YES;
             
             if (completed){
                 NSLog(@"Activity: %@ Share completado",activityType);
             }else{
                 NSLog(@"Activity: %@ Error compartiendo o cancelado por usuario. Error: %@",activityType,activityError);
             }
         }];
    }
}


#pragma mark - Gesture

-(void)toggleCameraType:(UISwipeGestureRecognizer*)recognizer{
    
    if ([recognizer direction] == UISwipeGestureRecognizerDirectionLeft && self.cameraCaptureModeVideo){
        //mirar UIViewAnimateWithDamping
        [UIView animateWithDuration:0.5
                              delay: 0.0
                            options: UIViewAnimationOptionCurveLinear
                         animations:^{
                                 self.selectorView.transform = CGAffineTransformMakeTranslation(-44, 0);
                         }
                         completion:^(BOOL finished){
                             self.cameraCaptureModeVideo = !self.cameraCaptureModeVideo;
                             [self dismissViewControllerAnimated:NO completion:NULL];
                         }];
    } else if([recognizer direction] == UISwipeGestureRecognizerDirectionRight && !self.cameraCaptureModeVideo){
        [UIView animateWithDuration:0.5
                              delay: 0.0
                            options: UIViewAnimationOptionCurveLinear
                         animations:^{
                                 self.selectorView.transform = CGAffineTransformMakeTranslation(0, 0);
                         }
                         completion:^(BOOL finished){
                             self.cameraCaptureModeVideo = !self.cameraCaptureModeVideo;
                             [self dismissViewControllerAnimated:NO completion:NULL];
                         }];
    }
    
}

@end
