//
//  RXArchiveANY.m
//  RXArchive
//
//  Created by srx on 2017/11/17.
//  Copyright © 2017年 SCM. All rights reserved.
//

#import "RXArchiveANY.h"
#import "SSZipArchive.h"
#include "zip.h"
#include "unzip.h"
#import "LZMAExtractor.h"
#import <UnrarKit/UnrarKit.h>
#import <CommonCrypto/CommonCrypto.h>


#define RXArchiveErrorDomain @"RXArchive"

static NSString * WORD_50  = @"504b03040a000000000087";
static NSString * EXCEL_50 = @"504b030414000600080000";
static NSString * ZIP_50   = @"504b03040a0000000000b9";
//504b0304140000080800e8 //好压 zip
//504b03040a00000000008c


static NSString *_FilepathStringMD5(NSString *string) {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}


#define RXLogANY(__format,  ...) printfLogANY([NSString stringWithFormat:@"%s", __FUNCTION__], __LINE__, [NSString stringWithFormat:(__format), ##__VA_ARGS__])
//#define RXLog(__format,  ...) printf("%s", __FUNCTION__)

#pragma mark - ~~~~~~~~~~~ 打印日志 ~~~~~~~~~~~~~~~
void printfLogANY(NSString * message, int line, NSString * method) {
#if DEBUG
    NSLog(@"\n method=%@, line = %zd\n %@ \n\n", method, line, message);
#endif
}

@interface RXArchiveANY()
<SSZipArchiveDelegate>
{
    NSString * _filePath;//路径
}
@end

@implementation RXArchiveANY
@synthesize lastPathComponent = _lastPathComponent;
@synthesize lastPathComponentName = _lastPathComponentName;

- (id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _filePath = path;
        [self typeOfIdentificationDocument];
    }
    return self;
}

- (id)initWithPath:(NSString *)path andPassword:(NSString*)password{
    if ((self = [super init])) {
        _filePath = path;
        _password = password;
        [self typeOfIdentificationDocument];
    }
    return self;
}

- (void)typeOfIdentificationDocument {
    _lastPathComponent = [_filePath lastPathComponent];
    NSArray * items = [_lastPathComponent componentsSeparatedByString:@"."];
    NSString * name = [items firstObject];
    if(name == nil) name = @"";
    for(NSInteger i = 1; i < items.count -1; i++) {
        name = [name stringByAppendingString:[NSString stringWithFormat:@".%@", items[i]]];
    }
    
    if(name.length == 0) {
        if(!([_lastPathComponent isEqualToString:self.decompressOptionPath ] ||
             [_lastPathComponent isEqualToString:self.compressOptionPath])) {
            name = _lastPathComponent;
        }
    }
    
    _lastPathComponentName = name;
    _fileType = [RXArchiveANY rx_fileTypeWithPath:_filePath];
}

+ (FILE_TYPE)rx_fileTypeWithPath:(NSString *)path {
    FILE_TYPE type = FILE_TYPE_Undefined;

    if(path == nil) return type;
   
    if(path.length == 0) return type;
    
    NSData * data = [NSData dataWithContentsOfFile:path];
    if(!data) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if(isDir) {
            //是文件夹
            type = FILE_TYPE_DIRECTORY;
        }
        return type;
    }
    
    
    if([URKArchive pathIsARAR:path]) {
        type = FILE_TYPE_RAR;
        return type;
    }
    
    zipFile zip = unzOpen(path.fileSystemRepresentation);
    if(zip) {
        type = FILE_TYPE_ZIP;
        return type;
    }
    
    uint8_t c;
    [data getBytes:&c length:1];
    RXLogANY(@"c=%x -swithc-\n", c);
    switch (c) {
            
            /** 图片 */
        case 0xFF: //FFD8FF(.JPEG .JPE  .JPG)
            type = FILE_TYPE_JPEG;
            break;
        case 0x89: //89504E47
            type = FILE_TYPE_PNG;
            break;
        case 0x47: //47494638(git、"GIF 87A"、"GIF 89A")
            type = FILE_TYPE_GIF;
            break;
        case 0x49: //49492A00
        case 0x4D: //424D
            type = FILE_TYPE_TIFF;
        case 0x52:
        {
        // R as RIFF for WEBP
        if (data.length < 12) {
            type = FILE_TYPE_Undefined;
            break;
        }
        
        NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
        RXLogANY(@"testString=%@", testString);
        if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
            type =  FILE_TYPE_WebP;
        }
        else if ([testString hasPrefix:@"Rar"]) {
            type = FILE_TYPE_RAR;
        }
        break;
        }
            /** 压缩包 */
        case 0x04: //0x04034b50 pkware
        case 0x50: //504B0304==zip/jar
        {
         //不要删除，这个是理解的一部分，文件头，是文件格式创始者开创的，还要根据
         //zip文件由三部分组成：压缩的文件内容源数据、压缩的目录源数据、目录结束标识结构
         
            uint32_t cc;
            [data getBytes:&cc length:4];
            if(cc == 0x04034b50) {
                //zip /word ...不知道有多少
                
                NSString * string = [self convertDataToHexStr:data];
                //        RXLogANY(@"string=%@", string);
                if(string.length > 22) {
                    NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                    string = [string substringToIndex:22];
                    RXLogANY(@"\n\nstring=%@\ntestString=%@\n", string, testString);
                    if([string isEqualToString:WORD_50]) {
                        type = FILE_TYPE_MS_WORD;
                    }
                    else if([string isEqualToString:EXCEL_50]) {
                        type = FILE_TYPE_MS_EXCEL;
                    }
                    else if([string isEqualToString:ZIP_50]) {
                        type = FILE_TYPE_ZIP;
                    }
                    
            }
            else if(cc == 0x041034b50) {
                type = FILE_TYPE_MS_EXCEL;
            }
            else {
                type = FILE_TYPE_Undefined;
            }
        
        }
            break;
        }
        case 0x37:
            type = FILE_TYPE_7zZIP;
            break;
            
            /** 文挡 */
        case 0xD0: //D0CF11E0
            type = FILE_TYPE_MS_WORD;
            break;
        case 0x21: //2142444E
        case 0xCF: //CFAD12FEC5FD746F
            type = FILE_TYPE_MS_OUTLOOK;
            break;
        case 0x7B: //7B5C727466
            type = FILE_TYPE_MS_RTF;
            break;
        case 0x25: //7B5C727466
            type = FILE_TYPE_MS_PDF;
            break;
        default:
        {
            type = FILE_TYPE_Undefined;
            RXLogANY(@"default\n");
            break;
        }
    }
    return type;
}

//二进制转16进制 的字符串
+ (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

- (NSString *)password {
    if(!_password) {
        _password = @"";
    }
    return _password;
}



- (NSString *)lastPathComponent {
    if(!_lastPathComponent) {
        _lastPathComponent = @"";
    }
    return _lastPathComponent;
}

- (NSString *)lastDocumentPath {
    if(_lastPathComponentName) {
        _lastPathComponentName = self.lastPathComponent;
    }
    return _lastPathComponentName;
}

- (NSString *)decompressOptionPath {
    NSString * path = [RXArchiveANY decompressOptionPath];
    return path;
}

- (NSString *)compressOptionPath {
    NSString * path = [RXArchiveANY compressOptionPath];
    return path;
}

+ (NSString *)decompressOptionPath {
    NSString * path = [self applicationDocumentsDirectory];
    path = [path stringByAppendingPathComponent:@"decompress_srxboys"];
    return path;
}

+ (NSString *)compressOptionPath {
    NSString * path = [self applicationDocumentsDirectory];
    path = [path stringByAppendingPathComponent:@"compress_srxboys"];
    return path;
}

+ (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark ---------------【 解压 】---------------
- (void)rx_decompressOfSuccess:(Success)sucess failure:(Failure)failure {
    _sucessBlock = sucess;
    _failureBlock = failure;
    
    RXLogANY(@"开始 【解压】");
    if(!RXFileTypeIsArchive(self.fileType)) {
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoContent userInfo:@{NSLocalizedDescriptionKey:@"不是压缩文件"}];
            _failureBlock(error);
        }
        return;
    }
    
    if(self.fileType == FILE_TYPE_ZIP) {
        [self rx_zipDecompress];
    }
    else if(self.fileType == FILE_TYPE_7zZIP){
        [self rx_7zZipDecompress];
    }
    else {
        [self rx_RARDecompress];
    }
}

#pragma mark ---------------【 压缩 】---------------
- (void)rx_compressOfSuccess:(Success)sucess failure:(Failure)failure {
    _sucessBlock = sucess;
    _failureBlock = failure;
    
    RXLogANY(@"开始 【压缩】");
}



#pragma mark ---------------【 根据格式(解压) 】---------------
- (void)rx_zipDecompress {
    
    NSString * newPath = [self.decompressOptionPath stringByAppendingPathComponent:[RXArchiveANY filepathStringMD5]];
    
    BOOL unzipped = [SSZipArchive unzipFileAtPath:_filePath toDestination:newPath overwrite:YES password:self.password progressHandler:nil completionHandler:nil];
    if ( !unzipped ) {
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoContent userInfo:@{NSLocalizedDescriptionKey:@"不是压缩文件"}];
            _failureBlock(error);
        }
        return;
    }
    
    NSError *error = nil;
    RXLogANY(@"documentPath=%@", newPath);
    NSArray<NSString *> *fileNames = [[NSFileManager defaultManager]
                                          contentsOfDirectoryAtPath:newPath
                                          error:&error];
    if (error) {
        RXLogANY(@"zip is read error=%@", error);
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoContent userInfo:@{NSLocalizedDescriptionKey:@"解压后没有内容"}];
            _failureBlock(error);
        }
        return;
    }
    
    if(fileNames.count == 0) {
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoContent userInfo:@{NSLocalizedDescriptionKey:@"解压后没有内容"}];
            _failureBlock(error);
        }
        return;
    }
    
    RXLogANY(@"Zip reading archive: filenames=%@", fileNames);
    
    if(_sucessBlock) {
        NSMutableArray * newFileNames = [NSMutableArray new];
        for(NSString * fileName in fileNames) {
            NSString * newFileName = [newPath stringByAppendingPathComponent:fileName];
            [newFileNames addObject:newFileName];
        }
        _sucessBlock(newFileNames, newPath);
    }
}


#pragma mark - - 7zZip 解压
- (void)rx_7zZipDecompress {
    
     NSString * newPath = [self.decompressOptionPath stringByAppendingPathComponent:[RXArchiveANY filepathStringMD5]];
    
    NSArray *contents = [LZMAExtractor extract7zArchive:_filePath dirName:newPath preserveDir:YES];
    if (![contents count]) {
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoDecompress userInfo:@{NSLocalizedDescriptionKey:@"不是压缩文件"}];
            _failureBlock(error);
        }
    }
    else{
        RXLogANY(@"7zZip reading archive: filenames=%@", contents);
        if(_sucessBlock) {
            _sucessBlock(contents, newPath);
        }
    }
}

#pragma mark - - RAR 解压
/*
 
- (void)rx_RARDecompress {
 Unrar4iOS.h 的编写
    Unrar4iOS *unrar = [[Unrar4iOS alloc] init];
    BOOL ok;
    if (self.password != nil && self.password.length > 0) {
        @try {
            ok = [unrar unrarOpenFile:_filePath withPassword:self.password];
        }
        @catch(NSException *exception) {
            RXLogANY(@"exception: %@", exception);
        }
    }
    else{
        ok = [unrar unrarOpenFile:_filePath];
    }
    
    if (ok) {
        NSArray *files = [unrar unrarListFiles];
        NSMutableArray *filePathsArray = [NSMutableArray array];
        for (NSString *filePath in files){
            [filePathsArray addObject:[self.decompressOptionPath stringByAppendingPathComponent:filePath]];
        }
        
        //        RXLogANY(@"_destinationPath : %@",_destinationPath);
        BOOL extracted = [unrar unrarFileTo:self.decompressOptionPath overWrite:YES];
        //        RXLogANY(@"extracted : %d",extracted);
        
        //        [self moveFilesToDestinationPathFromCompletePaths:filePathsArray withFilePaths:files];
        if ( extracted ) {
            if(_sucessBlock) {
                NSString * path = [self.decompressOptionPath stringByAppendingPathComponent:self.lastPathComponent];
                _sucessBlock(filePathsArray, path);
            }
        }
        else{
            if(_failureBlock) {
                _failureBlock(ArchiveANYErrorNoContent);
            }
        }
        [unrar unrarCloseFile];
    }
    else{
        if(_failureBlock) {
            _failureBlock(ArchiveANYErrorNoDecompress);
        }
        [unrar unrarCloseFile];
    }
}
*/

- (void)rx_RARDecompress {
    NSError *archiveError = nil;
    URKArchive *archive;
    if (self.password != nil && self.password.length > 0) {
        archive = [[URKArchive alloc] initWithPath:_filePath password:self.password error:&archiveError];
    }
    else {
        archive = [[URKArchive alloc] initWithPath:_filePath error:&archiveError];
    }
    
    if (!archive) {
        if(_failureBlock) {
           NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoDecompress userInfo:@{NSLocalizedDescriptionKey:@"不是压缩文件"}];
            _failureBlock(error);
        }
        return;
    }
    
     NSString * newPath = [self.decompressOptionPath stringByAppendingPathComponent:[RXArchiveANY filepathStringMD5]];
    
    NSError * extractFileError = nil;
    BOOL isExtractFile = [archive extractFilesTo:newPath overwrite:YES progress:nil error:&extractFileError];
    if(!isExtractFile) {
        RXLogANY(@"Error reading archive: %@", extractFileError);
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoContent userInfo:@{NSLocalizedDescriptionKey:@"解压后没有内容"}];
            _failureBlock(error);
        }
        return;
    }
    
    
    NSError *error = nil;
    NSArray *filenames = [archive listFilenames:&error];
    if (error) {
        RXLogANY(@"Error reading archive: %@", error);
        if(_failureBlock) {
            NSError * error = [[NSError alloc] initWithDomain:RXArchiveErrorDomain code:ArchiveANYErrorNoContent userInfo:@{NSLocalizedDescriptionKey:@"解压后没有内容"}];
            _failureBlock(error);
        }
        return;
    }
    
    RXLogANY(@"RAR reading archive: filenames=%@", filenames);
    
    if(_sucessBlock) {
        NSString * path = [newPath stringByAppendingPathComponent:self.lastPathComponentName];
        NSMutableArray * newFileNames = [NSMutableArray new];
        for(NSString * fileName in filenames) {
            NSString * newFileName = [path stringByAppendingPathComponent:fileName];
            [newFileNames addObject:newFileName];
        }
        _sucessBlock(newFileNames, path);
    }
}

+ (NSString *)filepathStringMD5 {
     NSString *string = [NSString stringWithFormat:@"RXArchiveANY_srxboys_%zd",[[NSDate date] timeIntervalSince1970]];
    return _FilepathStringMD5(string);
}


#pragma mark ---------------【 根据格式(压缩) 】---------------

@end
