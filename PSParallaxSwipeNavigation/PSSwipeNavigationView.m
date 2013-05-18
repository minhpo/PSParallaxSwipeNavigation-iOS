/**
 Copyright (c) 2013 Po Sam <minhpo@gmail.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <QuartzCore/QuartzCore.h>
#import <math.h>

#import "PSSwipeNavigationView.h"
#import "PSSwipeNavigationDelegate.h"

static const float kAnimationDuration = 0.3f;

typedef enum {
    RotationDirectionLeft,
    RotationDirectionRight
} RotationDirection;

@interface PSSwipeNavigationView ()

// Container to hold all added views
@property (nonatomic, retain) NSMutableArray *pages;
@property (nonatomic, retain) NSMutableArray *screenShots;

// Reference to current page
@property (nonatomic, retain) UIView *currentPage;

// Reference to current page index in views container
@property (assign) NSInteger currentPageIndex;

// Initial values
@property (assign) CGFloat initialPinchScale;
@property (assign) CGFloat marginX;
@property (assign) CGFloat marginY;
@property (assign) CGFloat minimizedPageHeight;

@end

@implementation PSSwipeNavigationView

#pragma mark - Public methods

#pragma mark > Life cycle

- (id)initWithFrame:(CGRect)frame andParameters:(NSDictionary*)parameters {
    self = [self initWithFrame:frame];
    
    if (self) {
        // Add and init the background view
        self.backgroundView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
        self.backgroundView.showsHorizontalScrollIndicator = NO;
        self.backgroundView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.backgroundView];
        
        // Add and init the content view
        self.contentView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
        self.contentView.showsHorizontalScrollIndicator = NO;
        self.contentView.showsVerticalScrollIndicator = NO;
        self.contentView.decelerationRate = UIScrollViewDecelerationRateFast;
        self.contentView.delegate = self;
        [self addSubview:self.contentView];
        
        // Setup the gesture recognizers
        [self initGestureRecognizers];
        
        // Extract and set parameter values
        if (parameters) {
            id parameter = [parameters objectForKey:PSSwipeNavigationViewParameterPageWidth];
            if (parameter && [parameter isKindOfClass:[NSNumber class]]) {
                self.pageWidth = [(NSNumber*)parameter floatValue];
            }
            else {
                self.pageWidth = self.frame.size.width;
            }
            
            parameter = [parameters objectForKey:PSSwipeNavigationViewParameterPageMargin];
            if (parameter && [parameter isKindOfClass:[NSNumber class]]) {
                self.pageMargin = [(NSNumber*)parameter floatValue];
            }
            else {
                self.pageMargin = 0.0f;
            }
            
            parameter = [parameters objectForKey:PSSwipeNavigationViewParameterParallaxFactor];
            if (parameter && [parameter isKindOfClass:[NSNumber class]]) {
                self.parallaxFactor = [(NSNumber*)parameter floatValue];
            }
            else {
                self.parallaxFactor = 1.0f;
            }
            
            parameter = [parameters objectForKey:PSSwipeNavigationViewParameterBackgroundImage];
            if (parameter && [parameter isKindOfClass:[NSString class]]) {
                UIImageView *backgroundImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:parameter]] autorelease];
                backgroundImageView.frame = CGRectMake(0.0f, 0.0f, backgroundImageView.frame.size.width, backgroundImageView.frame.size.height);
                [self.backgroundView addSubview:backgroundImageView];
            }
        }
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.pages = [NSMutableArray arrayWithCapacity:0];
        self.screenShots = [NSMutableArray arrayWithCapacity:0];
        
        self.currentPageIndex = 0;
    }
    return self;
}

- (void)dealloc {
    self.tapRecognizer = nil;
    self.twoFingerVerticalSwipeRecognizer = nil;
    self.twoFingerLeftSwipeRecognizer = nil;
    self.twoFingerRightSwipeRecognizer = nil;
    self.pinchRecognizer = nil;
    
    self.contentView = nil;
    self.backgroundView = nil;
    
    self.pages = nil;
    self.screenShots = nil;
    self.currentPage = nil;
    
    [super dealloc];
}

#pragma mark > Misc method

- (void)initializeView {
    // Set decelerate rate to fast
    self.contentView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    // Setup the gesture recognizers
    [self initGestureRecognizers];
    
    // Calculate the horizontal margin between the outer pages and the screen
    self.marginX = (self.contentView.frame.size.width - self.pageWidth) / 2;
    
    // Calculate the minimized page height
    self.minimizedPageHeight = ((self.pageWidth-self.pageMargin)/self.contentView.frame.size.width)*self.contentView.frame.size.height;
    
    // Calculate the vertical margin between the pages and the screen
    self.marginY = (self.contentView.frame.size.height - self.minimizedPageHeight) / 2;
}

/**
 * Method to add views in at the correct location
 */
- (void)addPage:(UIView*)page {
    // Set gesture recognizers for view and subviews
    [self setupTwoFingerGestureRecognizersForScrollViewsInViewRecursively:page];
    
    // Add page to local container for reference
    if (!self.pages)
        self.pages = [NSMutableArray arrayWithCapacity:0];
    [self.pages addObject:page];
    
    // If current page is not set yet, then add page as current page in maximized state
    if (!self.currentPage) {
        self.currentPage = page;
        [self.contentView addSubview:self.currentPage];
    }
    
    UIView *screenShot = [self capturePage:page];
    
    // Add screen shot to local container for selection
    if (!self.screenShots)
        self.screenShots = [NSMutableArray arrayWithCapacity:0];
    [self.screenShots addObject:screenShot];
    
    // Minimze the view for display in the navigation mode
    screenShot.frame = CGRectMake(((self.screenShots.count - 1) * self.pageWidth) + self.marginX + (self.pageMargin / 2), self.marginY, self.pageWidth - self.pageMargin, self.minimizedPageHeight);
    
    // Add screen shot to scroll view for display
    [self.contentView addSubview:screenShot];
    [self.contentView sendSubviewToBack:screenShot];
    
    // Calculate the new content size
    self.contentView.contentSize = CGSizeMake((self.pages.count * self.pageWidth) + (self.marginX * 2), self.contentView.frame.size.height);
}

/**
 * Public method to enter navigation mode
 */
- (void)minimizePages {
    if (self.twoFingerVerticalSwipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown)
        [self handleTwoFingerVerticalSwipeGesture:self.twoFingerVerticalSwipeRecognizer];
}

/**
 * Public method to exit navigation mode
 */
- (void)maximizeCurrentPage {
    if (self.twoFingerVerticalSwipeRecognizer.direction == UISwipeGestureRecognizerDirectionUp)
        [self handleTwoFingerVerticalSwipeGesture:self.twoFingerVerticalSwipeRecognizer];
}

#pragma mark > IBActions

/**
 * Callback method to handle vertical swipe gesture while attempting to enter and exit navigation mode
 */
- (IBAction)handleTwoFingerVerticalSwipeGesture:(UISwipeGestureRecognizer*)recognizer {
    // Detect swipe direction
    if (recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        // Enter navigation mode
        [self enterNavigationModeWithRefresh:YES];
        
        // Invoke callback method
        if ([self.psSwipeNavigationDelegate respondsToSelector:@selector(didEnterNavigation)])
            [self.psSwipeNavigationDelegate didEnterNavigation];
        
        // Change to opposite swipe direction for symetric action
        self.twoFingerVerticalSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
        
        // Enable tap gesture recognizer
        self.tapRecognizer.enabled = YES;
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionUp) {
        // Exit navigation mode
        [self exitNavigationMode];
        
        // Invoke callback method
        if ([self.psSwipeNavigationDelegate respondsToSelector:@selector(didExitNavigation)])
            [self.psSwipeNavigationDelegate didExitNavigation];
        
        // Change to opposite swipe direction for symetric action
        self.twoFingerVerticalSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
        
        // Disable tap gesture recognizer
        self.tapRecognizer.enabled = NO;
    }
}

/**
 * Callback method to handle horizontal swipe gesture while attempting to enter navigation mode
 */
- (IBAction)handleTwoFingerHorizontalSwipeGesture:(UISwipeGestureRecognizer*)recognizer {
    // Check direction for processing
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        // Check if processing is allowed
        if (self.currentPageIndex < self.pages.count - 1) {
            // Force enter of navigation mode
            [self handleTwoFingerVerticalSwipeGesture:self.twoFingerVerticalSwipeRecognizer];
            
            UIView *screenShot = (UIView*)[self.screenShots objectAtIndex:self.currentPageIndex];
            [self rotateView:screenShot direction:RotationDirectionLeft];
            
            // Scroll to next page
            CGPoint targetContentOffset = CGPointMake(self.contentView.contentOffset.x + self.pageWidth, 0);
            [self snapToNearestPage:targetContentOffset];
        }
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        // Check if processing is allowed
        if (self.currentPageIndex > 0) {
            // Force enter of navigation mode
            [self handleTwoFingerVerticalSwipeGesture:self.twoFingerVerticalSwipeRecognizer];
            
            UIView *screenShot = (UIView*)[self.screenShots objectAtIndex:self.currentPageIndex];
            [self rotateView:screenShot direction:RotationDirectionRight];
            
            // Scroll to next page
            CGPoint targetContentOffset = CGPointMake(self.contentView.contentOffset.x - self.pageWidth, 0);
            [self snapToNearestPage:targetContentOffset];
        }
    }
}

- (void)rotateView:(UIView*)view direction:(RotationDirection)direction {
    CGFloat angle = direction == RotationDirectionLeft ? M_PI : -M_PI;
    
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    theAnimation.values = [NSArray arrayWithObjects:
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0, 0,1,0)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle, 0,1,0)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle * 2, 0,1,0)],
                           nil];
    
    theAnimation.cumulative = YES;
    theAnimation.duration = kAnimationDuration;
    theAnimation.repeatCount = 0;
    theAnimation.removedOnCompletion = YES;
    
    
    theAnimation.timingFunctions = [NSArray arrayWithObjects:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                    nil
                                    ];
    
    [view.layer addAnimation:theAnimation forKey:@"transform"];
}


/**
 * Callback method to handle vertical swipe gesture while attempting to exit navigation mode
 */
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer*)recognizer {
    // Normalize the current scale so that the visual increase is roughly the same regardless of the initial pinch scale
    CGFloat normalizedScale = recognizer.scale/self.initialPinchScale;
    
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        // Calculate the new width
        CGFloat newWidth = (self.pageWidth - self.pageMargin) * sqrt(normalizedScale);
        
        // Calculate the new height
        CGFloat newHeight = self.minimizedPageHeight * sqrt(normalizedScale);
        
        // Do not allow new width and height to exceed screen boundaries
        if (newWidth > self.contentView.frame.size.width || newHeight > self.contentView.frame.size.height) {
            newWidth = self.contentView.frame.size.width;
            newHeight = self.contentView.frame.size.height;
        }

        // Retrieve the selected view
        UIView *view = (UIView*)[self.screenShots objectAtIndex:self.currentPageIndex];
        
        // Bring view to the front to avoid getting obscured by other views
        [self.contentView bringSubviewToFront:view];
        
        // Set the new size
        CGPoint center = view.center;
        CGRect newRect = CGRectMake(center.x - newWidth/2, center.y - newHeight/2, newWidth, newHeight);
        
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [UIView animateWithDuration:0.1 animations:^() {
                view.frame = newRect;
            }];
        }
        else
            view.frame = newRect;
    }
    else {
        if (normalizedScale > self.initialPinchScale * 2.0f) {
            // Force exit of navigation mode
            [self handleTwoFingerVerticalSwipeGesture:self.twoFingerVerticalSwipeRecognizer];
        }
        else {
            [self enterNavigationModeWithRefresh:NO];
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)recognizer {
    // Force exit of navigation mode
    [self handleTwoFingerVerticalSwipeGesture:self.twoFingerVerticalSwipeRecognizer];
}

#pragma mark - Private methods

/**
 * Method to setup all required gesture recognizers on main view
 */
- (void)initGestureRecognizers {
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapRecognizer.numberOfTapsRequired = 1;
    self.tapRecognizer.numberOfTouchesRequired = 1;
    self.tapRecognizer.enabled = NO;
    self.tapRecognizer.cancelsTouchesInView = YES;
    self.tapRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.tapRecognizer];
    
    // Add gesture recognizers
    self.twoFingerVerticalSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerVerticalSwipeGesture:)];
    self.twoFingerVerticalSwipeRecognizer.numberOfTouchesRequired = 2;
    self.twoFingerVerticalSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    self.twoFingerVerticalSwipeRecognizer.enabled = YES;
    self.twoFingerVerticalSwipeRecognizer.cancelsTouchesInView = YES;
    self.twoFingerVerticalSwipeRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.twoFingerVerticalSwipeRecognizer];
    
    self.twoFingerLeftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerHorizontalSwipeGesture:)];
    self.twoFingerLeftSwipeRecognizer.numberOfTouchesRequired = 2;
    self.twoFingerLeftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    self.twoFingerLeftSwipeRecognizer.enabled = YES;
    self.twoFingerLeftSwipeRecognizer.cancelsTouchesInView = YES;
    self.twoFingerLeftSwipeRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.twoFingerLeftSwipeRecognizer];
    
    self.twoFingerRightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerHorizontalSwipeGesture:)];
    self.twoFingerRightSwipeRecognizer.numberOfTouchesRequired = 2;
    self.twoFingerRightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    self.twoFingerRightSwipeRecognizer.enabled = YES;
    self.twoFingerRightSwipeRecognizer.cancelsTouchesInView = YES;
    self.twoFingerRightSwipeRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.twoFingerRightSwipeRecognizer];
    
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    self.pinchRecognizer.scale = 1.0f;
    self.initialPinchScale = self.pinchRecognizer.scale;
    self.pinchRecognizer.enabled = NO;
    self.pinchRecognizer.cancelsTouchesInView = YES;
    self.pinchRecognizer.delaysTouchesBegan = YES;
    [self.pinchRecognizer requireGestureRecognizerToFail:self.twoFingerVerticalSwipeRecognizer];
    [self addGestureRecognizer:self.pinchRecognizer];
}

/**
 * Method to enter the navigation mode
 */
- (void)enterNavigationModeWithRefresh:(BOOL)shouldRefresh {
    if (shouldRefresh) {
        // Remove the old screen shot of the current page from the content view
        UIView *screenShotOfCurrentPage = [self.screenShots objectAtIndex:self.currentPageIndex];
        [screenShotOfCurrentPage removeFromSuperview];
        
        // Retrieve the current page from the current page index
        self.currentPage = (UIView*)[self.pages objectAtIndex:self.currentPageIndex];
        
        // Get the latest screen shot of the current page
        screenShotOfCurrentPage = [self capturePage:self.currentPage];
        screenShotOfCurrentPage.frame = self.currentPage.frame;
        
        // Replace the old screen shot with the latest screen shot
        [self.screenShots replaceObjectAtIndex:self.currentPageIndex withObject:screenShotOfCurrentPage];
        
        // Add the new screen shot to the content view
        [self.contentView addSubview:screenShotOfCurrentPage];
        
        // Bring the new screen shot to the front to avoid getting obscured
        [self.contentView bringSubviewToFront:screenShotOfCurrentPage];
        
        // Remove the current page from the content view
        [self.currentPage removeFromSuperview];
    }
    
    // Enable scroll navigation
    self.contentView.scrollEnabled = YES;
    
    // Enable gesture recognizers
    self.pinchRecognizer.enabled = YES;
    
    for (NSInteger i=0; i<self.screenShots.count; i++) {
        UIView *screenShot = (UIView*)[self.screenShots objectAtIndex:i];
        
        // Minimize every screen shot
        [UIView animateWithDuration:kAnimationDuration animations:^ {
            screenShot.frame = CGRectMake(i*self.pageWidth + self.marginX + (self.pageMargin / 2), self.marginY, self.pageWidth - self.pageMargin, self.minimizedPageHeight);
        }];
    }
}

/**
 * Method to exit the navigation mode
 */
- (void)exitNavigationMode {
    // Disable scroll navigation
    self.contentView.scrollEnabled = NO;
    
    // Disable horizontal swipe gesture recognizers
    self.pinchRecognizer.enabled = NO;
    
    // Retrieve the current page from the current page index
    self.currentPage = (UIView*)[self.pages objectAtIndex:self.currentPageIndex];
    
    // Get the screen of the current page index
    UIView *screenShotOfCurrentView = [self.screenShots objectAtIndex:self.currentPageIndex];
    
    // Bring the screen shot to the front to obscure all other pages
    [self.contentView bringSubviewToFront:screenShotOfCurrentView];
    
    // Maximize the current page
    [UIView animateWithDuration:kAnimationDuration
                     animations:^ {
                         // Maximize the screen shot
                         screenShotOfCurrentView.frame = CGRectMake(self.contentView.contentOffset.x, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         // Set the size and position for the current page
                         self.currentPage.frame = screenShotOfCurrentView.frame;
                         
                         // Add the current page to the content view for display
                         [self.contentView addSubview:self.currentPage];
                         
                         // Bring the current page to the front to obscure all other content
                         [self.contentView bringSubviewToFront:self.currentPage];
                     }];
}

/**
 * Method to capture a page in an UIImageView
 */
- (UIImageView*)capturePage:(UIView*)page {
    UIGraphicsBeginImageContextWithOptions(page.bounds.size, YES, [[UIScreen mainScreen] scale]);
    [page.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImageView *screenShotView = [[[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()] autorelease];
    screenShotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    return screenShotView;
}

/**
 * Method to snap to the nearest page given the current offset
 */
- (void)snapToNearestPage {
    [self snapToNearestPage:self.contentView.contentOffset];
}

/**
 * Method to snap to the nearest page of the target point
 */
- (void)snapToNearestPage:(CGPoint)targetContentOffset {
    if (targetContentOffset.x < 0)
        self.currentPageIndex = 0;
    else if (targetContentOffset.x > self.contentView.contentSize.width - self.contentView.frame
             .size.width)
        self.currentPageIndex = self.pages.count - 1;
    else {
        CGPoint contentOffset = targetContentOffset;
        CGFloat offsetX = contentOffset.x;
        
        self.currentPageIndex = 0;
        
        while (offsetX > self.pageWidth) {
            self.currentPageIndex++;
            offsetX -= self.pageWidth;
        }
        
        // Set page index to next page, if offset exceeds half the page width
        if (offsetX > self.pageWidth/2)
            self.currentPageIndex++;
        
        // Set current page index to last page if exceeding the last page index
        if (self.currentPageIndex >= self.pages.count)
            self.currentPageIndex = self.pages.count - 1;
        
        CGPoint targetPoint = CGPointMake(self.currentPageIndex*self.pageWidth, 0);
        [self.contentView setContentOffset:targetPoint animated:YES];
    }
}

/**
 * Method to recursively setup a two finger swipe for all scrollviews in a view
 */
- (void)setupTwoFingerGestureRecognizersForScrollViewsInViewRecursively:(UIView*)view {
    
    for (UIView *subview in view.subviews) {
        [self setupTwoFingerGestureRecognizersForScrollViewsInViewRecursively:subview];
    }
    
    [self setupTwoFingerGestureRecognizersForScrollViewsInView:view];
}

/**
 * Method to setup a two finger swipe for a view
 */
- (void)setupTwoFingerGestureRecognizersForScrollViewsInView:(UIView*)view {
    // Create a new instance of the swipe gesture
    UISwipeGestureRecognizer *twoFingerVerticalSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerVerticalSwipeGesture:)];
    twoFingerVerticalSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    twoFingerVerticalSwipe.numberOfTouchesRequired = 2;
    [view addGestureRecognizer:twoFingerVerticalSwipe];
    
    UISwipeGestureRecognizer *twoFingerLeftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerHorizontalSwipeGesture:)];
    twoFingerLeftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    twoFingerLeftSwipe.numberOfTouchesRequired = 2;
    [view addGestureRecognizer:twoFingerLeftSwipe];
    
    UISwipeGestureRecognizer *twoFingerRightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerHorizontalSwipeGesture:)];
    twoFingerRightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    twoFingerRightSwipe.numberOfTouchesRequired = 2;
    [view addGestureRecognizer:twoFingerRightSwipe];
    
    // Create a pan gesture recognizer to intercept all pan gestures with two fingers
    UIPanGestureRecognizer *twoFingerPan = [[UIPanGestureRecognizer alloc] init];
    twoFingerPan.minimumNumberOfTouches = 2;
    twoFingerPan.maximumNumberOfTouches = 2;
    [view addGestureRecognizer:twoFingerPan];
    
    // Create a relation for the two finger pan recognizer to fail when the two finger swipe recognizer succeeds
    [twoFingerPan requireGestureRecognizerToFail:twoFingerVerticalSwipe];
    [twoFingerPan requireGestureRecognizerToFail:twoFingerLeftSwipe];
    [twoFingerPan requireGestureRecognizerToFail:twoFingerRightSwipe];
    
    [twoFingerPan release];
    [twoFingerVerticalSwipe release];
}

#pragma mark - UIScrollViewDelegate

/**
 * Snap to nearest page on end of deceleration
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self snapToNearestPage];
}

/**
 * Snap to nearest page on end of drag
 */
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self snapToNearestPage:(*targetContentOffset)];
}

/**
 * Manual scroll the backgound during scroll to create parallax effect
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentViewOffset = self.contentView.contentOffset;
    CGPoint backgroundViewOffset = CGPointMake(contentViewOffset.x/self.parallaxFactor, contentViewOffset.y);
    if (backgroundViewOffset.x < 0)
        backgroundViewOffset = CGPointMake(0, contentViewOffset.y);
    
    self.backgroundView.contentOffset = backgroundViewOffset;
}

@end
