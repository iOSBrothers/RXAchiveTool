//
//  RXFileHandleANY.h
//  RXArchive
//
//  Created by srx on 2017/11/30.
//  Copyright © 2017年 SCM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RXArchiveHeader.h"

@interface RXFileHandleANY : NSObject
@property (nonatomic, assign, readonly) FILE_TYPE fileType;
@property (nonatomic, copy, readonly) NSString * filePath;
@property (nonatomic, copy, readonly) NSString * filePathComponent;
@property (nonatomic, copy, readonly) NSString * fileName;
@property (nonatomic, copy, readonly) NSDate * fileModDate;
@property (nonatomic, copy, readonly) NSDate * fileCreateDate;
@property (nonatomic, assign, readonly) unsigned long long fileSize;

+ (RXFileHandleANY *)initWithFilePath:(NSString *)filePath;
@end
