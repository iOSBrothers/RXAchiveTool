//
//  Unrar4iOS.h
//  Unrar4iOS
//
//  Created by Rogerio Pereira Araujo on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
/*
 *  废弃 请使用 https://github.com/abbeycode/UnrarKit
 *
 * 改库 已使用 UnrarKit
 */

#import <Foundation/Foundation.h>
#import <Unrar4iOS/raros.hpp>
#import <Unrar4iOS/dll.hpp>

@interface Unrar4iOS : NSObject {

	HANDLE	 _rarFile;
	struct	 RARHeaderDataEx *header;
	struct	 RAROpenArchiveDataEx *flags;
	NSString *filename;
	NSString *password;
}

@property(nonatomic, retain) NSString* filename;
@property(nonatomic, retain) NSString* password;

-(BOOL) unrarOpenFile:(NSString*) rarFile;
-(BOOL) unrarOpenFile:(NSString*) rarFile withPassword:(NSString*) aPassword;
-(NSArray *) unrarListFiles;
-(BOOL) unrarFileTo:(NSString*) path overWrite:(BOOL) overwrite;
-(NSData *) extractStream:(NSString *)aFile;
-(BOOL) unrarCloseFile;

@end
