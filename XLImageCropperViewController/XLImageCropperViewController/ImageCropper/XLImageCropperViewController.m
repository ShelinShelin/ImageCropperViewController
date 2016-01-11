//
//  XLImageCropperViewController.m
//  GDImageCropperViewController
//
//  Created by Shelin on 16/1/11.
//  Copyright © 2016年 GreatGate. All rights reserved.
//

#import "XLImageCropperViewController.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

static CGFloat const kBoundceDuation = 0.2f;

@interface XLImageCropperViewController ()
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UIButton *cancelBtn;

@property (nonatomic, strong) UIImageView *showImgView;
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UIView *circularView;

@property (nonatomic, strong) UIImage *originalImage;//原始图片
@property (nonatomic, strong) UIImage *editedImage;//裁剪后图片

@property (nonatomic, assign) CGRect oldFrame;
@property (nonatomic, assign) CGRect largeFrame;
@property (nonatomic, assign) CGFloat limitRatio;//限制缩放比例

@property (nonatomic, assign) CGRect latestFrame;

@property (nonatomic, assign) CGRect cropFrame;//裁剪尺寸

@property (nonatomic, copy) CropperFinishedBlock finishedBlock;
@property (nonatomic, copy) CropperCancelBlock cancelBlock;

@end

@implementation XLImageCropperViewController
#pragma mark - methods

- (id)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio {
    if (self = [super init]) {
        self.cropFrame = cropFrame;
        self.limitRatio = limitRatio;
        self.originalImage = [self fixOrientation:originalImage];
    }
    return self;
}

- (void)imageCropperViewControllerWithCropperFinished:(CropperFinishedBlock)finishedBlock {
    self.finishedBlock = finishedBlock;
}

- (void)imageCropperViewControllerWithCropperCancel:(CropperCancelBlock)cancelBlock {
    self.cancelBlock = cancelBlock;
}

#pragma mark - life cyle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self addControlBtn];
    self.view.backgroundColor = [UIColor blackColor];
}

#pragma mark - lazy load

- (UIImageView *)showImgView {
    if (!_showImgView) {
        _showImgView = [[UIImageView alloc] init];
        [_showImgView setMultipleTouchEnabled:YES];
        [_showImgView setUserInteractionEnabled:YES];
        _showImgView.image = self.originalImage;
    }
    return _showImgView;
}

- (UIView *)coverView {
    if (!_coverView) {
        
        _coverView = [[UIView alloc] initWithFrame:self.view.bounds];
        _coverView.alpha = 0.5f;
        _coverView.backgroundColor = [UIColor blackColor];
        _coverView.userInteractionEnabled = NO;
        _coverView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        //镂空中间圆形
        [self overlayViewClip];
    }
    return _coverView;
}

- (UIView *)circularView {
    if (!_circularView) {
        _circularView = [[UIView alloc] initWithFrame:self.cropFrame];
        _circularView.layer.cornerRadius = self.cropFrame.size.width / 2.0f;
        _circularView.layer.borderColor = [UIColor whiteColor].CGColor;
        _circularView.layer.borderWidth = 1.0f;
    }
    return _circularView;
}

- (UIButton *)confirmBtn {
    if (!_confirmBtn) {
        _confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth - 100.0f, kScreenHeight - 50.0f, 100.0f, 50.f)];
        _confirmBtn.backgroundColor = [UIColor blackColor];
        _confirmBtn.titleLabel.textColor = [UIColor whiteColor];
        [_confirmBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
        [_confirmBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_confirmBtn.titleLabel setNumberOfLines:0];
        [_confirmBtn addTarget:self action:@selector(confirmBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmBtn;
}

- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, kScreenHeight - 50.0f, 100.0f, 50.0f)];
        _cancelBtn.backgroundColor = [UIColor blackColor];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
        [_cancelBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_cancelBtn addTarget:self action:@selector(cancelBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

#pragma mark - UI

- (void)initView {
    
    // scale to fit the screen
    CGFloat oriWidth = self.cropFrame.size.width;
    CGFloat oriHeight = self.originalImage.size.height * (oriWidth / self.originalImage.size.width);
    CGFloat oriX = self.cropFrame.origin.x + (self.cropFrame.size.width - oriWidth) / 2;
    CGFloat oriY = self.cropFrame.origin.y + (self.cropFrame.size.height - oriHeight) / 2;
    self.oldFrame = CGRectMake(oriX, oriY, oriWidth, oriHeight);
    self.latestFrame = self.oldFrame;
    self.showImgView.frame = self.oldFrame;
    
    self.largeFrame = CGRectMake(0, 0, self.limitRatio * self.oldFrame.size.width, self.limitRatio * self.oldFrame.size.height);
    
    [self addGestureRecognizers];
    
    [self.view addSubview:self.showImgView];
    
    //遮盖
    [self.view addSubview:self.coverView];
    
    //裁剪范围
    [self.view addSubview:self.circularView];
}

- (void)addControlBtn {
    [self.view addSubview:self.cancelBtn];
    [self.view addSubview:self.confirmBtn];
}

//裁剪遮盖中间圆形
- (void)overlayViewClip {
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    //rectangle
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, kScreenHeight)];
    [path addLineToPoint:CGPointMake(kScreenWidth, kScreenHeight)];
    [path addLineToPoint:CGPointMake(kScreenWidth, 0)];
    [path closePath];
    //center circular
    CGPoint center = CGPointMake(self.cropFrame.origin.x + (self.cropFrame.size.width / 2), self.cropFrame.origin.y + (self.cropFrame.size.height / 2));
    UIBezierPath *roundPath = [UIBezierPath bezierPathWithArcCenter:center radius:self.cropFrame.size.width / 2.0f startAngle:0.0f endAngle:M_PI * 2 clockwise:YES];
    [path appendPath:roundPath];
    
    maskLayer.path = path.CGPath;
    self.coverView.layer.mask = maskLayer;
}

#pragma mark - Button Click

- (void)cancelBtnClick:(id)sender {
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(XLImageCropperDelegate)]) {
        [self.delegate imageCropperDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
}

- (void)confirmBtnClick:(id)sender {
    if (self.delegate && [self.delegate conformsToProtocol:@protocol(XLImageCropperDelegate)]) {
        [self.delegate imageCropper:self didFinished:[self getEditedImage]];
    }
    if (self.finishedBlock) {
        self.finishedBlock(self, [self getEditedImage]);
    }
}

#pragma mark - add gestures

- (void)addGestureRecognizers {
    // add pinch gesture
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    
    // add pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
}

#pragma mark - gesture handler

- (void)pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    UIView *view = self.showImgView;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
        pinchGestureRecognizer.scale = 1;
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleScaleOverflow:newFrame];
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:kBoundceDuation animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

- (void)panView:(UIPanGestureRecognizer *)panGestureRecognizer {
    UIView *view = self.showImgView;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // calculate accelerator
        CGFloat absCenterX = self.cropFrame.origin.x + self.cropFrame.size.width / 2;
        CGFloat absCenterY = self.cropFrame.origin.y + self.cropFrame.size.height / 2;
        CGFloat scaleRatio = self.showImgView.frame.size.width / self.cropFrame.size.width;
        CGFloat acceleratorX = 1 - ABS(absCenterX - view.center.x) / (scaleRatio * absCenterX);
        CGFloat acceleratorY = 1 - ABS(absCenterY - view.center.y) / (scaleRatio * absCenterY);
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
    else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // bounce to original frame
        CGRect newFrame = self.showImgView.frame;
        newFrame = [self handleBorderOverflow:newFrame];
        [UIView animateWithDuration:kBoundceDuation animations:^{
            self.showImgView.frame = newFrame;
            self.latestFrame = newFrame;
        }];
    }
}

// bounce to original frame
- (CGRect)handleScaleOverflow:(CGRect)newFrame {
    
    CGPoint oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width / 2, newFrame.origin.y + newFrame.size.height / 2);
    if (newFrame.size.width < self.oldFrame.size.width) {
        newFrame = self.oldFrame;
    }
    if (newFrame.size.width > self.largeFrame.size.width) {
        newFrame = self.largeFrame;
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width/2;
    newFrame.origin.y = oriCenter.y - newFrame.size.height/2;
    return newFrame;
}

- (CGRect)handleBorderOverflow:(CGRect)newFrame {
    // horizontally
    if (newFrame.origin.x > self.cropFrame.origin.x) newFrame.origin.x = self.cropFrame.origin.x;
    if (CGRectGetMaxX(newFrame) < self.cropFrame.size.width) newFrame.origin.x = self.cropFrame.size.width - newFrame.size.width;
    // vertically
    if (newFrame.origin.y > self.cropFrame.origin.y) newFrame.origin.y = self.cropFrame.origin.y;
    if (CGRectGetMaxY(newFrame) < self.cropFrame.origin.y + self.cropFrame.size.height) {
        newFrame.origin.y = self.cropFrame.origin.y + self.cropFrame.size.height - newFrame.size.height;
    }
    // adapt horizontally rectangle
    if (self.showImgView.frame.size.width > self.showImgView.frame.size.height && newFrame.size.height <= self.cropFrame.size.height) {
        newFrame.origin.y = self.cropFrame.origin.y + (self.cropFrame.size.height - newFrame.size.height) / 2;
    }
    return newFrame;
}

- (UIImage *)getEditedImage {
    
    CGRect circularFrame = self.cropFrame;
    CGFloat scaleRatio = self.latestFrame.size.width / self.originalImage.size.width;
    CGFloat x = (circularFrame.origin.x - self.latestFrame.origin.x) / scaleRatio;
    CGFloat y = (circularFrame.origin.y - self.latestFrame.origin.y) / scaleRatio;
    CGFloat w = circularFrame.size.width / scaleRatio;
    CGFloat h = circularFrame.size.width / scaleRatio;
    if (self.latestFrame.size.width < self.cropFrame.size.width) {
        CGFloat newW = self.originalImage.size.width;
        CGFloat newH = newW * (self.cropFrame.size.height / self.cropFrame.size.width);
        x = 0; y = y + (h - newH) / 2;
        w = newH; h = newH;
    }
    if (self.latestFrame.size.height < self.cropFrame.size.height) {
        CGFloat newH = self.originalImage.size.height;
        CGFloat newW = newH * (self.cropFrame.size.width / self.cropFrame.size.height);
        x = x + (w - newW) / 2; y = 0;
        w = newH; h = newH;
    }
    
    //裁剪圆形
    CGRect myImageRect = CGRectMake(x, y, w, h);
    CGImageRef imageRef = self.originalImage.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect);
    CGSize size;
    size.width = myImageRect.size.width;
    size.height = myImageRect.size.height;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myImageRect, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    
    UIGraphicsBeginImageContextWithOptions(smallImage.size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect circleRect = CGRectMake(0, 0, smallImage.size.width, smallImage.size.height);
    CGContextAddEllipseInRect(ctx, circleRect);
    CGContextClip(ctx);
    [smallImage drawInRect:circleRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - fixOrientation

- (UIImage *)fixOrientation:(UIImage *)originalImage {
    
    // No-op if the orientation is already correct
    if (originalImage.imageOrientation == UIImageOrientationUp)
        return originalImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (originalImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, originalImage.size.width, originalImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, originalImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, originalImage.size.height);
            transform = CGAffineTransformRotate(transform, - M_PI_2);
            break;
        default:
            break;
    }
    
    switch (originalImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, originalImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, originalImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, originalImage.size.width, originalImage.size.height,
                                             CGImageGetBitsPerComponent(originalImage.CGImage), 0,
                                             CGImageGetColorSpace(originalImage.CGImage),
                                             CGImageGetBitmapInfo(originalImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (originalImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0, 0 ,originalImage.size.height,originalImage.size.width), originalImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, originalImage.size.width,originalImage.size.height), originalImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end
