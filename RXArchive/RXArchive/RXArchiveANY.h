//
//  RXArchiveANY.h
//  RXArchive
//
//  Created by srx on 2017/11/17.
//  Copyright © 2017年 SCM. All rights reserved.
//
//
//
//




#import <Foundation/Foundation.h>
#import "RXArchiveHeader.h"
#import "RXFileHandleANY.h"


typedef void(^Success)(NSArray *fileComponents, NSString * filePath);
typedef void(^Failure)(NSError *error);

@interface RXArchiveANY : NSObject

/** 解压的目录(包含特定的目录名) */
@property (nonatomic, copy, readonly) NSString * decompressOptionPath;
/** 压缩的目录(包含特定的目录名) */
@property (nonatomic, copy, readonly) NSString * compressOptionPath;

@property (nonatomic, copy, readonly) NSString * lastPathComponent;
@property (nonatomic, copy, readonly) NSString * lastPathComponentName;
/** 所在目录的某个文件类型，如果是目录则为noKnow */
@property (nonatomic, assign, readonly) FILE_TYPE fileType;
@property (nonatomic, copy) NSString * password;
@property (nonatomic, assign) BOOL LogEnabel __deprecated_msg("未启用");

/** 完成【压缩/解压】的block */
@property (nonatomic, copy) Success sucessBlock;
/** 失败【压缩/解压】的block */
@property (nonatomic, copy) Failure failureBlock;

/** 需要压缩/解压的目录 */
- (id)initWithPath:(NSString *)path;
/** 需要压缩/解压(需要密码)的目录 */
- (id)initWithPath:(NSString *)path andPassword:(NSString*)password;

/** 文件类型 */
+ (FILE_TYPE)rx_fileTypeWithPath:(NSString *)path;
/** 解压的目录(包含特定的目录名) */
+ (NSString *)decompressOptionPath;
/** 压缩的目录(包含特定的目录名) */
+ (NSString *)compressOptionPath;

+(NSString *)filepathStringMD5;

/** 开始解压 */
- (void)rx_decompressOfSuccess:(Success)sucess failure:(Failure)failure;
/** 开始压缩 [还没有写]*/
- (void)rx_compressOfSuccess:(Success)sucess failure:(Failure)failure;

@end



/*
    需要 哪些系统库
     1、CoreGraphics.framework  (RAR)
     2、libz.tbd
 
 http://blog.csdn.net/rrrfff/article/details/7484109
 
    这里没有采用线程。
 */
