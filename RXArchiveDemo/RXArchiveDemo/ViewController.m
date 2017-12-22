//
//  ViewController.m
//  RXArchiveDemo
//
//  Created by srx on 2017/11/17.
//  Copyright © 2017年 SCM. All rights reserved.
//

#import "ViewController.h"
#import <RXArchive/RXArchive.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RXArchiveANY * archiveANY = [[RXArchiveANY alloc] initWithPath: [self getFilePath]];
    NSLog(@"archiveANY.fileType=%zd", archiveANY.fileType);
    
    
    if(RXFileTypeIsDocument(archiveANY.fileType)) {
        NSLog(@"12345");
    }
    
    [archiveANY rx_decompressOfSuccess:^(NSArray *fileComponents, NSString *filePath) {
        NSLog(@"%@\n \nfilepath=%@\n", fileComponents, filePath);
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
    

    RXFileHandleANY * fileHandle = [RXFileHandleANY initWithFilePath:[self getFilePath]];
    if(RXFileTypeIsDocument(fileHandle.fileType)) {
        NSLog(@"12345");
    }
/*
    RXArchiveANY * archiveANY2 = [[RXArchiveANY alloc] initWithPath: [self getWithExcel]];
    NSLog(@"%zd", archiveANY2.fileType);
    if(RXFileTypeIsDocument(archiveANY2.fileType)) {
        NSLog(@"\nyes yes\n");
    }
    else {
        NSLog(@"\nNO NO NO =%zd\n", archiveANY2.fileType);
    }
    
    
    RXArchiveANY * archiveANY3 = [[RXArchiveANY alloc] initWithPath: [self getWithZipExaple_pwd]];
    NSLog(@"%zd", archiveANY3.fileType);
    
*/
    
}

- (NSString *)getFilePath {
//---------------------
    NSInteger selectedIndex = 1;
//---------------------
    if(selectedIndex == 0) {
        return [self getWithexample7z];
    }
    else if(selectedIndex == 1) {
        return [self getWithZipExaple_pwd];
    }
    else if(selectedIndex == 2) {
        return [self getWithExampleRAR];
    }
    else if(selectedIndex == 3) {
        return [self getWithExcel];
    }
    else if(selectedIndex == 4) {
        return [self getWithWord1];
    }
    else if(selectedIndex == 5) {
        return [self getWithWord2];
    }
    else if(selectedIndex == 6) {
        return [self getWithZipHaoYa];
    }

    return nil;
}


- (NSString *)bundleFileName:(NSString *)name  ofType:(NSString *)type {
    return  [[NSBundle mainBundle] pathForResource:name ofType:type];
}

- (NSString *)getWithexample7z {
    return [self bundleFileName:@"example" ofType:@"7z"];
}

- (NSString *)getWithZipExaple_pwd {
    return [self bundleFileName:@"Zip_Example_pwd" ofType:@"zip"];
}

- (NSString *)getWithExampleRAR {
    return [self bundleFileName:@"example" ofType:@"rar"];
}

- (NSString *)getWithExcel {
    return [self bundleFileName:@"excel" ofType:@"xlsx"];
}
- (NSString *)getWithWord1 {
    return [self bundleFileName:@"技能" ofType:@"docx"];
}

- (NSString *)getWithWord2 {
    return [self bundleFileName:@"文档1" ofType:@"docx"];
}

- (NSString *)getWithZipHaoYa {
    return [self bundleFileName:@"好压文本文档" ofType:@"zip"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
