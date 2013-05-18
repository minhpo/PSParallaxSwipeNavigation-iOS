//
//  TestScrollViewController.m
//  PSParallaxSwipeNavigation
//
//  Created by Po Sam | The Mobile Company on 5/18/13.
//  Copyright (c) 2013 Po Sam. All rights reserved.
//

#import "TestScrollViewController.h"

@interface TestScrollViewController ()
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@end

@implementation TestScrollViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.scrollView.contentSize = CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.imageView = nil;
    self.scrollView = nil;
    
    [super dealloc];
}

@end
