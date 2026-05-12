#pragma once
#import <UIKit/UIKit.h>

@protocol GameLibraryDelegate <NSObject>
- (void)gameLibraryDidSelectISO:(NSString*)isoPath;
- (void)gameLibraryDidSelectBIOS:(NSString*)biosPath;
@end

@interface GameLibraryViewController : UIViewController
    <UIDocumentPickerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id<GameLibraryDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<NSString*>* isoFiles;

- (void)scanForGames;
- (void)importISO;
- (void)importBIOS;

@end