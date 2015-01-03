//
//  RCLoginViewController.m
//  RadChat
//
//  Created by Zachary Weiner on 1/3/15.
//  Copyright (c) 2015 com.mostbestawesome. All rights reserved.
//

#import "RCLoginViewController.h"
#import <PFFacebookUtils.h>
#import "RCConstants.h"
#import <Parse/Parse.h>
@interface RCLoginViewController ()
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSMutableData *imageData;
@end

@implementation RCLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        [self updateUserInformation];
        NSLog(@"the user is already signed in");
        [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)loginButtonPressed:(UIButton *)sender {
    NSArray *permissionsArray = @[ @"user_about_me", @"user_interests", @"user_relationships", @"user_birthday", @"user_location", @"user_relationship_details"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [self.activityIndicator stopAnimating]; // stop animation of activity indicator
        if (!user) {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"The Facebook login was cancelled." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
                
            } else {
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
            
        } else {
            [self updateUserInformation];
            [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
        }
    }];
    [self.activityIndicator startAnimating]; // Show loading indicator until login is finished
}

#pragma mark Helpers
- (void)updateUserInformation
{
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            NSDictionary *userDictionary = (NSDictionary *)result;
            NSString *facebookId = userDictionary[@"id"];
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookId]];
            NSMutableDictionary *userProfile = [[NSMutableDictionary alloc] initWithCapacity:8];
            if(userDictionary[@"name"]){
                userProfile[kRCUserProfileNameKey] = userDictionary[@"name"];
            }
            if(userDictionary[@"first_name"]){
                userProfile[kRCUserProfileFirstNameKey] = userDictionary[@"first_name"];
            }
            if(userDictionary[@"location"][@"name"]){
                userProfile[kRCUserProfileLocationKey] = userDictionary[@"location"][@"name"];
            }
            if(userDictionary[@"gender"]){
                userProfile[kRCUserProfileGenderKey] = userDictionary[@"gender"];
            }
            if(userDictionary[@"birthday"]){
                userProfile[kRCUserProfileBirthdayKey] = userDictionary[@"birthday"];
            }
            if(userDictionary[@"interested_in"]){
                userProfile[kRCUserProfileInterestedInKey] = userDictionary[@"interested_in"];
            }
            if([pictureURL absoluteString]){
                userProfile[kRCUserProfilePictureURL] = [pictureURL absoluteString];
            }
            
            [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
            [[PFUser currentUser] saveInBackground];
            [self requestImage];
        }else{
            NSLog(@"Error in facebook request");
        }
    }];
}


- (void) requestImage{
    PFQuery *query = [PFQuery queryWithClassName:kRCPhotoClassKey];
    [query whereKey:kRCPhotoUserKey equalTo:[PFUser currentUser]];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if(error){
            NSLog(@"error getting user picture");
            return ;
        }
        if(number == 0){
            // get and se tthe profile image
            self.imageData = [[NSMutableData alloc] init];
            
            NSURL *profileImageUrl = [[NSURL alloc] initWithString:[PFUser currentUser][kRCUserProfileKey][kRCUserProfilePictureURL]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:profileImageUrl];
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            if(!connection){
                NSLog(@"there was an errorin the connection for ProfileImage");
            }
        }else{
            NSLog(@"the number of pictures returned is NOT 0");
        }
    }];

}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.imageData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //Save image to parse
    UIImage *imageFromData = [UIImage imageWithData:self.imageData];
    [self uploadPFFiletoParse:imageFromData];
    
    
}

- (void)uploadPFFiletoParse:(UIImage *)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if(!imageData){
        NSLog(@"there was an error getting data from the image");
        return;
    }
    
    PFFile *photoFile = [PFFile fileWithData:imageData];
    [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            NSLog(@"error saving the profile photo to PFFile");
        }
        
        PFObject *photo = [PFObject objectWithClassName:kRCPhotoClassKey];
        [photo setObject:[PFUser currentUser] forKey:kRCPhotoUserKey];
        [photo setObject:photoFile forKey:kRCPhotoPictureKey];
        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                if(succeeded){
                    NSLog(@"Saved PhotoFile PFObject after saving Image data");
                }else{
                    NSLog(@"Error saving PhotoFile PFObject after saving Image data");
                }
            }
        }];
    }];
}

@end
