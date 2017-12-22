//
//  RXFileHandleANY.m
//  RXArchive
//
//  Created by srx on 2017/11/30.
//  Copyright © 2017年 SCM. All rights reserved.
//

#import "RXFileHandleANY.h"
#import "RXArchiveANY.h"
//
//@interface RXFileHandleANY()
//@property (nonatomic, assign) FILE_TYPE HandleFileType;
//@property (nonatomic, copy) NSString * HandleFilePath;
//@property (nonatomic, copy) NSString * HandleLastPathComponent;
//@property (nonatomic, copy) NSString * HandleFileName;
//@property (nonatomic, copy) NSDate * HandleFileDate;
//@end

@implementation RXFileHandleANY



+ (RXFileHandleANY *)initWithFilePath:(NSString *)filePath {
    RXFileHandleANY * fileHandle = [RXFileHandleANY new];
    fileHandle->_fileType = [RXArchiveANY rx_fileTypeWithPath:filePath];
    fileHandle->_filePath = filePath;
    if(filePath.length > 0) {
        NSString * lastPathComponent = [filePath lastPathComponent];
        NSString * fileName = [[lastPathComponent componentsSeparatedByString:@"."] firstObject];
        if(lastPathComponent.length > 0 && fileName.length == 0) {
            fileName = lastPathComponent;//不是文件是目录
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        
        if (fileAttributes != nil) {
            NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
            NSString *fileOwner = [fileAttributes objectForKey:NSFileOwnerAccountName];
            NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
            NSDate *fileCreateDate = [fileAttributes objectForKey:NSFileCreationDate];
            if (fileSize) {
//                NSLog(@"File size: %qi\n", [fileSize unsignedLongLongValue]);
                fileHandle->_fileSize = [fileSize unsignedLongLongValue];
            }
            if (fileOwner) {
//                NSLog(@"Owner: %@\n", fileOwner);
            }
            if (fileModDate) {
//                NSLog(@"Modification date: %@\n", fileModDate);
                fileHandle->_fileModDate = fileModDate;
            }
            if (fileCreateDate) {
//                NSLog(@"create date:%@\n", fileCreateDate);
                fileHandle->_fileCreateDate = fileCreateDate;
            }
        }  
      
        
        fileHandle->_filePathComponent = lastPathComponent;
        fileHandle->_fileName = fileName;
    }
    return fileHandle;
}


@end
