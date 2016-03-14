//
//  ViewController.m
//  XLImageCropperViewController
//
//  Created by Shelin on 16/1/11.
//  Copyright © 2016年 GreatGate. All rights reserved.
//

#import "ViewController.h"
#import "XLImageCropperViewController.h"
#define isIphoneSimulator TARGET_IPHONE_SIMULATOR

@interface ViewController () <XLImageCropperDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (nonatomic, strong)  UIImagePickerController *imagePickerController;

@end

@implementation ViewController

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
    }
    return _imagePickerController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (IBAction)toGetPhotos:(id)sender {
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:@"选择图片来源" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self selectImageFromCamera];
        
    }];
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self selectImageFromAlbum];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertViewController addAction:cameraAction];
    [alertViewController addAction:photoAction];
    [alertViewController addAction:cancelAction];
    [self presentViewController:alertViewController animated:YES completion:nil];
    
}

- (void)selectImageFromCamera {
    if (isIphoneSimulator) return;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

- (void)selectImageFromAlbum {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info {
    
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    CGRect cropFrame = CGRectMake((self.view.frame.size.width - 200) / 2.0, (self.view.frame.size.height - 200) / 2.0, 200, 200);
    
    XLImageCropperViewController *imageCropperViewController = [[XLImageCropperViewController alloc] initWithImage:originalImage cropFrame:cropFrame limitScaleRatio:3.0f];
    imageCropperViewController.delegate = self;
    
    /*
     [imageCropperViewController imageCropperViewControllerWithCropperCancel:^(XLImageCropperViewController *imageCropperViewController) {
     NSLog(@"imageCropperDidCancel");
     
     }];
     [imageCropperViewController imageCropperViewControllerWithCropperFinished:^(XLImageCropperViewController *imageCropperViewController, UIImage *editedImage) {
     NSLog(@"didFinished");
     }];
     */
    
    [picker presentViewController:imageCropperViewController animated:YES completion:nil];
}


#pragma mark - GDImageCropperDelegate

- (void)imageCropper:(XLImageCropperViewController *)imageCropperViewController didFinished:(UIImage *)editedImage {
//    NSLog(@"didFinished");
    self.iconView.image = editedImage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropperDidCancel:(XLImageCropperViewController *)imageCropperViewController {
//    NSLog(@"imageCropperDidCancel");
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
