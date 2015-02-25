//
//  RCRCameraViewController.m
//  CameraWithShare
//
//  Created by Ramón Carnero Rojo on 24/2/15.
//  Copyright (c) 2015 Ramón Carnero Rojo. All rights reserved.
//

#import "RCRCameraViewController.h"

@interface RCRCameraViewController ()
@property (strong, nonatomic) NSURL* urlVideo;
@end

@implementation RCRCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self createImagePicker];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(139, 270, 37, 37)];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.imagePicker.view addSubview:self.activityIndicator];
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
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
}

- (void) createImagePicker {
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    self.imagePicker.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
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
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    NSURL *videoURL = [info valueForKey:UIImagePickerControllerMediaURL];
    NSString *pathToVideo = [videoURL path];
    
        BOOL okToSaveVideo = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToVideo);
    
        if (okToSaveVideo) {
            self.urlVideo = videoURL;
            UISaveVideoAtPathToSavedPhotosAlbum(pathToVideo, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
        } else {
            [self video:pathToVideo didFinishSavingWithError:nil contextInfo:NULL];
        }
    
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    NSLog(@"Cancel, en una App normal quitaríamos el view controller de la cámara");
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if (error) {
        //Deprecated
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Guardado incorrecto"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
        [alert show];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Video Guardado" message:@"Almacenado en el carrete" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {[self shareVideoWithURL:self.urlVideo];}];
        
        [alert addAction:defaultAction];
        [self.imagePicker presentViewController:alert animated:NO completion:nil];
    }
}


//Hay que tener mucho cuidado con la jerarquía de vistas. Tengo que mostrar el AlertControl encima del picker. Si lo presento en la view, estaré presentándolo detrás del picker. El sistema eliminará datos del AlertControl para ahorrar memoria, fallando.

#pragma mark - ActivityViewController

- (void)shareVideoWithURL:(NSURL *)urlVideo {
    
    //Utilizando ActivityController a pelo comparte vídeo por Message, Mail, Fotos de iCloud, Facebook, Google+, Evernote, Telegram. No twitter (esperemos que ahora añadan el comportamiento)
    if(urlVideo != nil)
    {
        NSArray *activityItems = @[urlVideo];
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
                             [self.activityIndicator startAnimating];
                             self.activityIndicator.hidden = NO;
                         }];
        
        [activityVC setCompletionWithItemsHandler:
         ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
             [self.activityIndicator stopAnimating];
             self.activityIndicator.hidden = YES;
             
             if (completed){
                 NSLog(@"Activity: %@ Share completado",activityType);
             }else{
                 NSLog(@"Activity: %@ Error compartiendo o cancelado por usuario. Error: %@",activityType,activityError);
             }
         }];
    }
}

@end
