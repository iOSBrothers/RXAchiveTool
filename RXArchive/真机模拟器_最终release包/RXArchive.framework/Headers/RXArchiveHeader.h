//
//  RXArchiveHeader.h
//  RXArchive
//
//  Created by srx on 2017/11/23.
//  Copyright © 2017年 SCM. All rights reserved.
//

#ifndef RXArchiveHeader_h
#define RXArchiveHeader_h

/*
     单选枚举
 */
typedef NS_ENUM(NSUInteger, FILE_TYPE){
    FILE_TYPE_Undefined = 0,
    
    /** 图片格式 */
    FILE_TYPE_JPEG = 1,/* */
    FILE_TYPE_PNG  = 2,/* */
    FILE_TYPE_GIF  = 3,/* */
    FILE_TYPE_TIFF = 4,/* */
    FILE_TYPE_WebP = 5,/* */
    
    /** 压缩包格式 */
    FILE_TYPE_RAR = 6, /* */
    FILE_TYPE_ZIP = 7, /* zip/jar/outdated */
    FILE_TYPE_7zZIP = 8,
    
    /* 文档格式 */
    FILE_TYPE_MS_WORD = 9,  /**  .docx  */
    
    FILE_TYPE_MS_EXCEL = 10, /* .xlsx */
    
    FILE_TYPE_MS_OUTLOOK = 11, /** .pst  .dbx  */
    
    FILE_TYPE_MS_RTF = 12, /* */
    
    FILE_TYPE_MS_PDF = 13, /* */
    
    /* 目录 directory*/
    FILE_TYPE_DIRECTORY
};



/*
     内联函数 (不允许内部for循环消耗的内存)
 优点:
     1.不会将函数压栈, 产生内存消耗
     2.宏需要预编译, 而内联函数是一个函数, 不需要预编译
 */
static inline BOOL RXFileTypeIsPic(FILE_TYPE fileType) {
    if(fileType == FILE_TYPE_DIRECTORY) return NO;
    return ((fileType) == FILE_TYPE_JPEG || (fileType) == FILE_TYPE_PNG ||
            (fileType) == FILE_TYPE_GIF  || (fileType) == FILE_TYPE_TIFF||
            (fileType) == FILE_TYPE_WebP );
}
static inline BOOL RXFileTypeIsArchive(FILE_TYPE fileType) {
    if(fileType == FILE_TYPE_DIRECTORY) return NO;
    return ((fileType) == FILE_TYPE_RAR || (fileType) == FILE_TYPE_ZIP ||
            (fileType) == FILE_TYPE_7zZIP );
}
static inline BOOL RXFileTypeIsDocument(FILE_TYPE fileType) {
    if(fileType == FILE_TYPE_DIRECTORY) return NO;
    return !(RXFileTypeIsPic(fileType) || RXFileTypeIsArchive(fileType));
}


typedef NS_ENUM(NSUInteger, ArchiveANYError) {
    ArchiveANYErrorNoKnow = 0, //不知道
    ArchiveANYErrorNoDecompress = 1, //不是 【解压文件】,切记不是动作
    ArchiveANYErrorNoCompress, //不是 【压缩文件】,切记不是动作
    ArchiveANYErrorNoContent  // 没有内容
};

#endif /* RXArchiveHeader_h */
