//
//  CXLog.h
//  OperationLog
//
//  Created by mac on 2017/8/29.
//  Copyright © 2017年 Jess. All rights reserved.
//

#ifndef DEBUG
#define CXLogD(format,...) NSLog(@"[DEBUG][%s-%d]:" format,__FUNCTION__,__LINE__,##__VA_ARGS__);
#define CXLogI(format,...) NSLog(@"[INFO][%s-%d]:"format,__FUNCTION__,__LINE__,##__VA_ARGS__);
#else
#define CXLogD(format,...)
#define CXLogI(format,...)
#endif /* CXLog_h */

/*
补充：
　　1) VA_ARGS 是一个可变参数的宏，很少人知道这个宏，这个可变参数的宏是新的C99规范中新增的，目前似乎只有gcc支持（VC6.0的编译器不支持）。宏前面加上##的作用在于，当可变参数的个数为0时，这里的##起到把前面多余的","去掉的作用,否则会编译出错, 你可以试试。
　　2) FILE 宏在预编译时会替换成当前的源文件名
　　3) LINE宏在预编译时会替换成当前的行号
　　4) FUNCTION宏在预编译时会替换成当前的函数名称
*/
