//
//  HRPGTableViewController.m
//  HabitRPG
//
//  Created by Phillip Thelen on 08/03/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import "HRPGProfileViewController.h"
#import "HRPGAppDelegate.h"
#import "HRPGTopHeaderNavigationController.h"
#import "Group.h"
#import "VTAcknowledgementsViewController.h"
#import <PDKeychainBindings.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIcon.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+iOS.h>

@interface HRPGProfileViewController ()

@property User *user;

@end

@implementation HRPGProfileViewController
NSString *username;
NSInteger userLevel;
NSString *currentUserID;
PDKeychainBindings *keyChain;
NIKFontAwesomeIconFactory *iconFactory;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![currentUserID isEqualToString:[keyChain stringForKey:@"id"]]) {
        //user has changed. Reload data.
        currentUserID = [keyChain stringForKey:@"id"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", currentUserID];
        [self.fetchedResultsController.fetchRequest setPredicate:predicate];
        NSError *error;
        [self.fetchedResultsController performFetch:&error];
        self.user = [self getUser];
        if (self.user) {
            username = self.user.username;
            userLevel = [self.user.level integerValue];
        }
        [self.tableView reloadData];
    }
    self.navigationItem.title = username;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    self.user = [self getUser];
    if (self.user) {
        username = self.user.username;
        userLevel = [self.user.level integerValue];
    } else {
        //User does not exist in database. Fetch it.
        [self refresh];
    }

    iconFactory = [NIKFontAwesomeIconFactory tabBarItemIconFactory];
    iconFactory.square = YES;
    iconFactory.renderingMode = UIImageRenderingModeAlwaysOriginal;
    
    UILabel* footerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 170)];
    footerView.text = [NSString stringWithFormat:NSLocalizedString(@"Hey! You are awesome!\nVersion %@ (%@)", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey]];
    footerView.textColor = [UIColor lightGrayColor];
    footerView.textAlignment = NSTextAlignmentCenter;
    footerView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    footerView.numberOfLines = 0;
    self.tableView.tableFooterView = footerView;
    
    HRPGTopHeaderNavigationController *navigationController = (HRPGTopHeaderNavigationController*) self.navigationController;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([navigationController getContentOffset],0,0,0);
    [self.tableView setContentInset:(UIEdgeInsetsMake([navigationController getContentOffset], 0, -150, 0))];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPartyData:) name:@"partyUpdated"  object:nil];
}

- (void)refresh {
    [self.sharedManager fetchUser:^() {
        [self.refreshControl endRefreshing];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
    }                     onError:^() {
        [self.refreshControl endRefreshing];
    }];
}


- (void)reloadPartyData:(id)sender {
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
}

- (User*)getUser {
    if ([[self.fetchedResultsController sections] count] > 0) {
        if ([[self.fetchedResultsController sections][0] numberOfObjects] > 0) {
            return (User *) [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        }
    }
    
    return nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            //Below level 10 users don't have spells
            if ([self.user.level integerValue] < 10 || [self.user.disableClass boolValue]) {
                return 0;
            } else {
                return 1;
            }
        case 1:
            return 2;
        case 2:
            return 5;
        case 3:
            return 3;
        default:
            return 0;
    }
}



- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return nil;
            break;
        case 1:
            return NSLocalizedString(@"Social", nil);
        case 2:
            return NSLocalizedString(@"Inventory", nil);
        case 3:
            return NSLocalizedString(@"About", nil);
        default:
            return @"";
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    iconFactory.colors = @[[UIColor darkGrayColor]];
    iconFactory.size = 16.f;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 37.5)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 14, 290, 17)];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor darkGrayColor];
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(9, 14, 16, 16)];
    iconView.contentMode = UIViewContentModeCenter;
    [view addSubview:label];
    [view addSubview:iconView];
    
    label.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];
    if (section == 1) {
        iconView.image = [iconFactory createImageForIcon:NIKFontAwesomeIconUsers];
    } else if (section == 2) {
        iconView.image = [iconFactory createImageForIcon:NIKFontAwesomeIconSuitcase];
    } else if (section == 3) {
        iconView.image = [iconFactory createImageForIcon:NIKFontAwesomeIconQuestionCircle];
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 0) {
        if (![self.user.selectedClass boolValue] && ![self.user.disableClass boolValue]) {
            [self performSegueWithIdentifier:@"SelectClassSegue" sender:self];
        } else {
            [self performSegueWithIdentifier:@"SpellSegue" sender:self];
        }
    } else if (indexPath.section == 1 && indexPath.item == 0) {
        [self performSegueWithIdentifier:@"TavernSegue" sender:self];
    } else if (indexPath.section == 1 && indexPath.item == 1) {
        [self performSegueWithIdentifier:@"PartySegue" sender:self];
        
    } else if (indexPath.section == 2 && indexPath.item == 0) {
        [self performSegueWithIdentifier:@"CustomizationSegue" sender:self];
    } else if (indexPath.section == 2 && indexPath.item == 1) {
        [self performSegueWithIdentifier:@"EquipmentSegue" sender:self];
    } else if (indexPath.section == 2 && indexPath.item == 2) {
        [self performSegueWithIdentifier:@"ItemSegue" sender:self];
    } else if (indexPath.section == 2 && indexPath.item == 3) {
        [self performSegueWithIdentifier:@"PetSegue" sender:self];
    } else if (indexPath.section == 2 && indexPath.item == 4) {
        [self performSegueWithIdentifier:@"MountSegue" sender:self];
        
    } else if (indexPath.section == 3 && indexPath.item == 0) {
        [self performSegueWithIdentifier:@"NewsSegue" sender:self];
    } else if (indexPath.section == 3 && indexPath.item == 1) {
        [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
    } else if (indexPath.section == 3 && indexPath.item == 2) {
        [self performSegueWithIdentifier:@"AboutSegue" sender:self];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = nil;
    NSString *cellName = @"Cell";
    BOOL showIndicator = NO;
    if (indexPath.section == 0 && indexPath.item == 0) {
        if (![self.user.selectedClass boolValue] && ![self.user.disableClass boolValue]) {
            title = NSLocalizedString(@"Select Class", nil);
        } else {
            if ([self.user.hclass isEqualToString:@"wizard"] || [self.user.hclass isEqualToString:@"healer"]) {
                title = NSLocalizedString(@"Cast Spells", nil);
            } else {
                title = NSLocalizedString(@"Use Skills", nil);
            }
        }
    } else if (indexPath.section == 1 && indexPath.item == 0) {
        title = NSLocalizedString(@"Tavern", nil);
    } else if (indexPath.section == 1 && indexPath.item == 1) {
        title = NSLocalizedString(@"Party", nil);
        
        User *user = [self getUser];
        if (user) {
            if ([user.party.unreadMessages boolValue]) {
                showIndicator = YES;
            }
        }
    } else if (indexPath.section == 2 && indexPath.item == 0) {
        title = NSLocalizedString(@"Customize Avatar", nil);
    } else if (indexPath.section == 2 && indexPath.item == 1) {
        title = NSLocalizedString(@"Equipment", nil);
    } else if (indexPath.section == 2 && indexPath.item == 2) {
        title = NSLocalizedString(@"Items", nil);
    } else if (indexPath.section == 2 && indexPath.item == 3) {
        title = NSLocalizedString(@"Pets", nil);
    } else if (indexPath.section == 2 && indexPath.item == 4) {
        title = NSLocalizedString(@"Mounts", nil);
    } else if (indexPath.section == 3 && indexPath.item == 0) {
        title = NSLocalizedString(@"News", nil);
        User *user = [self getUser];
        if (user) {
            if ([user.habitNewStuff boolValue]) {
                showIndicator = YES;
            }
        }
    } else if (indexPath.section == 3 && indexPath.item == 1) {
        title = NSLocalizedString(@"Settings", nil);
    } else if (indexPath.section == 3 && indexPath.item == 2) {
        title = NSLocalizedString(@"About", nil);
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName forIndexPath:indexPath];
    UILabel *label = (UILabel *) [cell viewWithTag:1];
    label.text = title;
    UIImageView *indicatorView = (UIImageView *) [cell viewWithTag:2];
    indicatorView.hidden = !showIndicator;
    if (showIndicator) {
        iconFactory.colors = @[[UIColor colorWithRed:0.372 green:0.603 blue:0.014 alpha:1.000]];
        iconFactory.size = 13.0f;
        indicatorView.image = [iconFactory createImageForIcon:NIKFontAwesomeIconCircle];
    }
    return cell;
}


- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    keyChain = [PDKeychainBindings sharedKeychainBindings];
    currentUserID = [keyChain stringForKey:@"id"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"id == %@", currentUserID]];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];

    [fetchRequest setSortDescriptors:sortDescriptors];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"username" cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            User *user = (User *) [self.fetchedResultsController objectAtIndexPath:newIndexPath];
            username = user.username;
            [tableView reloadData];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:3]] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            username = nil;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        case NSFetchedResultsChangeMove:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

@end
