#import "GameLibraryViewController.h"

@interface GameLibraryViewController ()
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSString* detectedBIOS;
@end

@implementation GameLibraryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.title = @"BionicSX2 — Select Game";
    self.isoFiles = [NSMutableArray array];

    UIBarButtonItem* helpBtn = [[UIBarButtonItem alloc]
        initWithTitle:@"?"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(showBIOSInstructions)];

    UIBarButtonItem* refreshBtn = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                             target:self
                             action:@selector(scanForGames)];

    self.navigationItem.rightBarButtonItems = @[refreshBtn, helpBtn];

    self.tableView = [[UITableView alloc]
        initWithFrame:self.view.bounds
                style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = UIColor.blackColor;
    [self.view addSubview:self.tableView];

    [self scanForGames];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scanForGames];
}

- (void)scanForGames {
    NSString* docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;

    [self.isoFiles removeAllObjects];
    NSArray* exts = @[@"iso", @"bin", @"img", @"chd"];
    NSFileManager* fm = [NSFileManager defaultManager];

    NSArray* contents = [fm contentsOfDirectoryAtPath:docs error:nil];
    for (NSString* f in contents) {
        NSString* ext = f.pathExtension.lowercaseString;
        if ([exts containsObject:ext] && ![f.lowercaseString hasPrefix:@"scph"]) {
            [self.isoFiles addObject:[docs stringByAppendingPathComponent:f]];
        }
    }

    NSString* gamesDir = [docs stringByAppendingPathComponent:@"games"];
    [fm createDirectoryAtPath:gamesDir
        withIntermediateDirectories:YES
                       attributes:nil error:nil];
    NSArray* games = [fm contentsOfDirectoryAtPath:gamesDir error:nil];
    for (NSString* f in games) {
        if ([exts containsObject:f.pathExtension.lowercaseString]) {
            [self.isoFiles addObject:[gamesDir stringByAppendingPathComponent:f]];
        }
    }

    [self.tableView reloadData];
    [self updateBIOSStatus];
}

- (void)updateBIOSStatus {
    NSString* docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString* biosDir = [docs stringByAppendingPathComponent:@"bios"];

    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:biosDir
        withIntermediateDirectories:YES
                       attributes:nil error:nil];

    NSArray* files = [fm contentsOfDirectoryAtPath:biosDir error:nil];
    NSString* bios = nil;
    for (NSString* f in files) {
        if ([f.pathExtension.lowercaseString isEqualToString:@"bin"]) {
            bios = f;
            break;
        }
    }

    self.detectedBIOS = bios;

    if (bios) {
        self.navigationItem.title = [NSString stringWithFormat:@"BionicSX2 ✓ %@", bios];
    } else {
        self.navigationItem.title = @"BionicSX2 — No BIOS";
    }
}

- (void)showBIOSInstructions {
    NSString* key = @"bios_instructions_shown";
    if ([[NSUserDefaults standardUserDefaults] boolForKey:key]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];

    UIAlertController* a = [UIAlertController
        alertControllerWithTitle:@"BIOS Required"
                         message:
        @"To run PS2 games:\n\n"
        @"1. Connect iPhone to Mac/PC\n"
        @"2. Open Finder → iPhone → Files → BionicSX2\n"
        @"3. Copy SCPH-XXXXX.bin to 'bios' folder\n"
        @"4. Copy ISO files to 'games' folder\n\n"
        @"Or use Files app → On My iPhone → BionicSX2"
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction
        actionWithTitle:@"Got it"
                  style:UIAlertActionStyleDefault
                handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s {
    return self.isoFiles.count ?: 1;
}

- (UITableViewCell*)tableView:(UITableView*)tv
        cellForRowAtIndexPath:(NSIndexPath*)ip {
    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:@"game"];
    if (!cell) {
        cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:@"game"];
        cell.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.detailTextLabel.textColor = UIColor.grayColor;
    }
    if (self.isoFiles.count == 0) {
        cell.textLabel.text = @"No games — add ISOs to Documents/games/";
        cell.detailTextLabel.text = @"";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        NSString* path = self.isoFiles[ip.row];
        NSDictionary* attr = [[NSFileManager defaultManager]
            attributesOfItemAtPath:path error:nil];
        double mb = [attr fileSize] / 1024.0 / 1024.0;
        cell.textLabel.text = path.lastPathComponent;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f MB", mb];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.row < self.isoFiles.count) {
        if (self.detectedBIOS) {
            [self.delegate gameLibraryDidSelectISO:self.isoFiles[ip.row]];
        } else {
            [self showBIOSInstructions];
        }
    }
}

@end