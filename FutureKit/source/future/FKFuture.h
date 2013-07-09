// 
// Copyright (c) 2013 Brian William Wolter. All rights reserved.
// 
// @LICENSE@
// 
// Developed in New York City
// 

@class FKFuture;

typedef id    (^FKFutureSuccessBlock)(id object);
typedef void  (^FKFutureFailureBlock)(NSError *error);

@interface FKFuture : NSObject

+(FKFuture *)future;
+(FKFuture *)futureWithSuccessBlock:(FKFutureSuccessBlock)success;
+(FKFuture *)futureWithFailureBlock:(FKFutureFailureBlock)failure;
+(FKFuture *)futureWithSuccessBlock:(FKFutureSuccessBlock)success failureBlock:(FKFutureFailureBlock)failure;

-(id)initWithSuccessBlock:(FKFutureSuccessBlock)success;
-(id)initWithFailureBlock:(FKFutureFailureBlock)failure;
-(id)initWithSuccessBlock:(FKFutureSuccessBlock)success failureBlock:(FKFutureFailureBlock)failure;

-(void)resolve;
-(void)resolve:(id)object;

-(void)error;
-(void)error:(NSError *)error;

-(FKFuture *)then:(FKFutureSuccessBlock)success, ... NS_REQUIRES_NIL_TERMINATION;
-(FKFuture *)then:(FKFutureSuccessBlock)success arguments:(va_list)arguments;

@property (readwrite, retain) FKFuture            * then;
@property (readonly)          FKFuture            * last;
@property (readwrite, copy)   FKFutureSuccessBlock  success;
@property (readwrite, copy)   FKFutureFailureBlock  failure;
@property (readonly, getter=isResolved) BOOL        resolved;

@end

static inline FKFuture * FKSuccess(FKFutureSuccessBlock block) {
  return [FKFuture futureWithSuccessBlock:block];
}

static inline FKFuture * FKFailure(FKFutureFailureBlock block) {
  return [FKFuture futureWithFailureBlock:block];
}

