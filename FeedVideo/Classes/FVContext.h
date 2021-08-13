//
//  FVContext.h
//  FBSnapshotTestCase
//
//  Created by Mark on 2021/5/25.
//

#import <Foundation/Foundation.h>
#import "FVContext.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *FVTriggerType NS_EXTENSIBLE_STRING_ENUM;
/// 框架自动触发，如页面滑动停止/页面刷新后/或者调用 recalculate 重新计算导致的事件
extern FVTriggerType const FVTriggerTypeAuto;
/// 使用方主动调用触发
extern FVTriggerType const FVTriggerTypeAppoint;
/// 续播触发
extern FVTriggerType const FVTriggerTypeContinue;

@interface FVContext : NSObject
/// 触发类型
@property (nonatomic, copy) FVTriggerType type;
/// 用户信息，透传
@property (nonatomic, copy, nullable) NSDictionary *userInfo;

@end

NS_INLINE FVContext *fv_context(FVTriggerType type, NSDictionary *_Nullable userInfo) {
    FVContext *context = [[FVContext alloc] init];
    context.type = type;
    context.userInfo = userInfo;
    return context;
}

NS_ASSUME_NONNULL_END
