//
//  RCProfileViewController.m
//  RadChat
//
//  Created by Zachary Weiner on 1/3/15.
//  Copyright (c) 2015 com.mostbestawesome. All rights reserved.
//

#import "RCProfileViewController.h"
#import <Parse/Parse.h>
#import "RCConstants.h"
@interface RCProfileViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation RCProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    PFQuery *query = [PFQuery queryWithClassName:kRCPhotoClassKey];
    [query whereKey:kRCPhotoUserKey equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"there was an error getting the picture for user");
            return;
        }
        if(objects.count > 0){
            PFFile *imageFile = objects[0][kRCPhotoPictureKey];
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                self.imageView.image = [UIImage imageWithData:data];
            }];
        }else{
            NSLog(@"There were no pictures in the collection");
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
