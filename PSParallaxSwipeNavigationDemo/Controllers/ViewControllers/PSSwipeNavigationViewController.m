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

#import "PSSwipeNavigationViewController.h"
#import "PSSwipeNavigationView.h"

@interface PSSwipeNavigationViewController () {
    // Array to hold view controllers
    NSMutableArray *viewControllers_;
}

@end

@implementation PSSwipeNavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        viewControllers_ = [[NSMutableArray arrayWithCapacity:0] retain];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.psSwipeNavigationView = nil;
    
    [viewControllers_ release], viewControllers_=nil;
    
    [super dealloc];
}

#pragma mark - Public methods

- (void)addViewControllers:(NSArray*)views {
    if (self.isViewLoaded) {
        for (UIViewController *viewController in views) {
            [self addViewController:viewController];
        }
    }
}

- (void)addViewController:(UIViewController*)viewController {
    [self.psSwipeNavigationView addPage:viewController.view];
}

#pragma mark - Private methods

#pragma mark - PSSwipeNavigationDelegate

- (void)didEnterNavigation {
    NSLog(@"PSSwipeNavigationViewController - didEnterNavigation");
}

- (void)didExitNavigation {
    NSLog(@"PSSwipeNavigationViewController - didExitNavigation");
}

@end
