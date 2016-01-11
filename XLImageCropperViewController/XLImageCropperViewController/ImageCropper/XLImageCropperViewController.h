//
//  XLImageCropperViewController.h
//  GDImageCropperViewController
//
//  Created by Shelin on 16/1/11.
//  Copyright © 2016年 GreatGate. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XLImageCropperViewController;

typedef void (^CropperFinishedBlock) (XLImageCropperViewController *imageCropperViewController, UIImage *editedImage);

typedef void (^CropperCancelBlock) (XLImageCropperViewController *imageCropperViewController);

@protocol XLImageCropperDelegate <NSObject>

@optional

- (void)imageCropper:(XLImageCropperViewController *)imageCropperViewController didFinished:(UIImage *)editedImage;

- (void)imageCropperDidCancel:(XLImageCropperViewController *)imageCropperViewController;

@end

@interface XLImageCropperViewController : UIViewController

@property (nonatomic, weak) id <XLImageCropperDelegate> delegate;

/**
 *  initialize
 */
- (id)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio;

- (void)imageCropperViewControllerWithCropperFinished:(CropperFinishedBlock)finishedBlock;

- (void)imageCropperViewControllerWithCropperCancel:(CropperCancelBlock)cancelBlock;

@end
