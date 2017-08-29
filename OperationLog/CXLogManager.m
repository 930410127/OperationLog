//
//  CXLogManager.m
//  OperationLog
//
//  Created by mac on 2017/8/29.
//  Copyright © 2017年 Jess. All rights reserved.
//

#import "CXLogManager.h"

@interface CXLogManager ()

@property (nonatomic, copy) NSString *logFilePath;

@property (nonatomic,strong)NSDateFormatter *formatter;

@end

#define FILEMAXSIZE (1024 * 1024 * 2)

@implementation CXLogManager

+ (id)CXLogManagerDefault{
    static CXLogManager *logManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logManager = [[CXLogManager alloc]init];
    });
    return logManager;
}

- (id)init{
    if (!(self = [super init])) {
        return self;
    }
    //将NSlog打印信息保存到Document目录下的Log文件夹下
    _logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject]stringByAppendingPathComponent:@"Log"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:_logFilePath]){
        [fileManager createDirectoryAtPath:_logFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (NSDateFormatter *)formatter{
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc]init];
        [_formatter setLocale:[[NSLocale alloc]initWithLocaleIdentifier:@"zh_CN"]];
        [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
    }
    return _formatter;
}

#pragma mark - app 日志文件记录，用于测试；
- (void)redirectNSLogToDocumentFolder{
    //如果连接终端（或Xcode）则不输出到文件
    //该函数用于检测输出 (STDOUT_FILENO) 是否重定向 是个 Linux 程序方法
    if (isatty(STDOUT_FILENO)) {
        return;
    }
    
    UIDevice *device = [UIDevice currentDevice];
    if ([device.model hasPrefix:@"Simulator"]) {//在模拟器不保存到文件中
        return;
    }
    
    [self limitLogFileSize];
    
    NSString *dateStr = [_formatter stringFromDate:[NSDate date]];
    NSString *logFilePath = [_logFilePath stringByAppendingFormat:@"/%@.log",dateStr];
    
    // 将log输入到文件 可以使用freopen函数重定向标准输出和标准出错文件
    freopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "a+", stderr);
    
    //捕获的Objective-C异常日志
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    
}

void UncaughtExceptionHandler(NSException* exception){
    
    //错误类型名称
    NSString *name = [exception name];
    //异常发生的原因
    NSString *reason = [exception reason];
    //异常发生时的调用栈
    NSArray *stackSymbols = [ exception callStackSymbols];

    ////将调用栈拼成输出日志的字符串
    NSMutableString *strSymbols = [[NSMutableString alloc]init];
    for (NSString *item in stackSymbols) {
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }
    
    ////将crash日志保存到Document目录下的Log文件夹下UncaughtException.log文件中
    NSString *crashLogFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject]stringByAppendingPathComponent:@"Log"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:crashLogFilePath]) {
        [fileManager createDirectoryAtPath:crashLogFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *crashLogFile = [crashLogFilePath stringByAppendingPathComponent:@"UncaughtException.log"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *crashString = [NSString stringWithFormat:@"<- %@ ->[ Uncaught Exception ]\r\nName: %@, Reason: %@\r\n[ Fe Symbols Start ]\r\n%@[ Fe Symbols End ]\r\n\r\n", dateStr, name, reason, strSymbols];
    
    if (![fileManager fileExistsAtPath:crashLogFile]) {
        [fileManager createDirectoryAtPath:crashLogFile withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:crashLogFile];
        [outFile seekToEndOfFile];
        [outFile writeData:[crashString dataUsingEncoding:NSUTF8StringEncoding]];
        [outFile closeFile];
    }
    
    //把错误日志发送到邮箱或者在下次启动app的时候上传到服务器
}

#pragma mark - 限制日志文件的大小
- (void)limitLogFileSize{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_logFilePath]) {
        return;
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_logFilePath];
    [fileHandle synchronizeFile];
    [fileHandle seekToEndOfFile];
    //文件大小
    unsigned long long fileSize = [fileHandle offsetInFile];
    if (fileSize > FILEMAXSIZE) {
        //将当前文件的操作位置设定为offset
        [fileHandle seekToFileOffset:fileSize * 0.45];
        NSData *data = [fileHandle readDataToEndOfFile];
        //将文件的字节设置为0，因为他可能包含数据
        [fileHandle truncateFileAtOffset:0];
        [fileHandle writeData:data];
        
    }
    [fileHandle closeFile];
}
@end
