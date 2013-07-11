//
//  SeafSettingsViewController.m
//  seafile
//
//  Created by Wang Wei on 10/27/12.
//  Copyright (c) 2012 Seafile Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SeafAppDelegate.h"
#import "SeafDetailViewController.h"
#import "SeafSettingsViewController.h"
#import "UIViewController+Extend.h"
#import "FileSizeFormatter.h"
#import "ColorfulButton.h"
#import "ExtentedString.h"
#import "Debug.h"

enum {
    CELL_INVITATION = 0,
    CELL_WEBSITE,
    CELL_SERVER,
    CELL_VERSION,
};

#define SEAFILE_SITE @"http://www.seafile.com"


@interface SeafSettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *nameCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *usedspaceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *serverCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cacheCell;
@property (strong, nonatomic) IBOutlet ColorfulButton *wipeCacheBt;
@property (strong, nonatomic) IBOutlet UITableViewCell *versionCell;
- (IBAction)wipeCache:(id)sender;
@property int state;

@end

@implementation SeafSettingsViewController
@synthesize connection = _connection;
@synthesize nameCell, usedspaceCell, serverCell, cacheCell, versionCell;
@synthesize wipeCacheBt;
@synthesize state = _state;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIColor *color = [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
    [wipeCacheBt setHighColor:color lowColor:[UIColor redColor]];
    self.navigationController.navigationBar.tintColor = BAR_COLOR;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureView];
    [_connection getAccountInfo:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureView
{
    if (!_connection)
        return;

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [infoDictionary objectForKey:@"CFBundleVersion"];
    versionCell.detailTextLabel.text = version;

    nameCell.detailTextLabel.text = _connection.username;
    serverCell.detailTextLabel.text = [_connection.address trimUrl];
    long long cacheSize = [Utils folderSizeAtPath:[[Utils applicationDocumentsDirectory] stringByAppendingPathComponent:@"objects"]];
    cacheCell.detailTextLabel.text = [FileSizeFormatter stringFromNumber:[NSNumber numberWithLongLong:cacheSize] useBaseTen:NO];
    Debug("%@, %lld, %lld, total cache=%lld", _connection.username, _connection.usage, _connection.quota, cacheSize);
    if (_connection.quota <= 0) {
        usedspaceCell.detailTextLabel.text = @"Unknown";
        return;
    }

    float usage = 100.0 * _connection.usage/_connection.quota;
    NSString *quotaString = [FileSizeFormatter stringFromNumber:[NSNumber numberWithLongLong:_connection.quota ] useBaseTen:NO];
    if (usage < 0)
        usedspaceCell.detailTextLabel.text = [NSString stringWithFormat:@"? of %@", quotaString];
    else
        usedspaceCell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f%% of %@", usage, quotaString];
}

- (void)setConnection:(SeafConnection *)connection
{
    _connection = connection;
}

#pragma mark - SSConnectionAccountDelegate
- (void)getAccountInfoResult:(BOOL)result connection:(SeafConnection *)conn
{
    if (result && conn == _connection) {
        [self configureView];
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    if (indexPath.section == 0) {
        if (indexPath.row == 1) // Select the quota cell
            [_connection getAccountInfo:self];
    } else if (indexPath.section == 1) {
    } else if (indexPath.section == 2) {
        _state = indexPath.row;
        switch ((indexPath.row)) {
            case CELL_INVITATION:
                [self sendMailInApp];
                break;

            case CELL_WEBSITE:
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:SEAFILE_SITE]];
                break;

            case CELL_SERVER:
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/", _connection.address]]];
                break;

            default:
                break;
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload {
    [self setNameCell:nil];
    [self setUsedspaceCell:nil];
    [self setServerCell:nil];
    [self setCacheCell:nil];
    [self setWipeCacheBt:nil];
    [self setVersionCell:nil];
    [super viewDidUnload];
}


#pragma mark - sena mail inside app
- (void)sendMailInApp
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (!mailClass) {
        [self alertWithMessage:@"This function is not supportted yet"];
        return;
    }
    if (![mailClass canSendMail]) {
        [self alertWithMessage:@"The mail account has not been set yet"];
        return;
    }
    [self displayMailPicker];
}

- (void)configureInvitationMail:(MFMailComposeViewController *)mailPicker
{
    [mailPicker setSubject:[NSString stringWithFormat:@"%@ invite you to Seafile", NSFullUserName()]];
    NSString *emailBody = [NSString stringWithFormat:@"Hey there!<br/><br/> I've been using Seafile and thought you might like it. It is a free way to bring all you files anywhere and share them easily.<br/><br/>Go to the official website of Seafile:</br></br> <a href=\"%@\">%@</a>\n\n", SEAFILE_SITE, SEAFILE_SITE];

    [mailPicker setMessageBody:emailBody isHTML:YES];
}

- (void)displayMailPicker
{
    SeafAppDelegate *appdelegate = (SeafAppDelegate *)[[UIApplication sharedApplication] delegate];
    MFMailComposeViewController *mailPicker = [[MFMailComposeViewController alloc] init];
    mailPicker.mailComposeDelegate = self;
    [self configureInvitationMail:mailPicker];
    [appdelegate.tabbarController presentViewController:mailPicker animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *msg;
    switch (result) {
        case MFMailComposeResultCancelled:
            msg = @"cancalled";
            break;
        case MFMailComposeResultSaved:
            msg = @"saved";
            break;
        case MFMailComposeResultSent:
            msg = @"sent";
            break;
        case MFMailComposeResultFailed:
            msg = @"failed";
            break;
        default:
            msg = @"";
            break;
    }
    Debug("state=%d:send mail %@\n", _state, msg);
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        SeafAppDelegate *appdelegate = (SeafAppDelegate *)[[UIApplication sharedApplication] delegate];
        [(SeafDetailViewController *)[appdelegate detailViewController:TABBED_SETTINGS] setPreViewItem:nil master:nil];
        [Utils clearAllFiles:[[Utils applicationDocumentsDirectory] stringByAppendingPathComponent:@"objects"]];
        [Utils clearAllFiles:[[Utils applicationDocumentsDirectory] stringByAppendingPathComponent:@"edit"]];
        [Utils clearAllFiles:[Utils applicationTempDirectory]];

        [appdelegate deleteAllObjects:@"Directory"];

        long long cacheSize = [Utils folderSizeAtPath:[[Utils applicationDocumentsDirectory] stringByAppendingPathComponent:@"objects"]];
        cacheCell.detailTextLabel.text = [FileSizeFormatter stringFromNumber:[NSNumber numberWithLongLong:cacheSize] useBaseTen:NO];
    }
}

- (IBAction)wipeCache:(id)sender
{
    NSString *title = @"Are you sure to clear all the cache ?";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [alertView show];
}
@end
