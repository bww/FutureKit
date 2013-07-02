// 
// Copyright (c) 2013 Brian William Wolter. All rights reserved.
// 
// @LICENSE@
// 
// Developed in New York City
// 

@class FKFuture;

typedef FKFuture * (^FKFutureSuccessBlock)(id object);
typedef void       (^FKFutureFailureBlock)(NSError *error);

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
-(void)error:(NSError *)error;

-(FKFuture *)then:(FKFutureSuccessBlock)success, ...;

@property (readwrite, retain) FKFuture            * then;
@property (readwrite, copy)   FKFutureSuccessBlock  success;
@property (readwrite, copy)   FKFutureFailureBlock  failure;

@end

static inline FKFuture * FKSuccess(FKFutureSuccessBlock block) {
  return [FKFuture futureWithSuccessBlock:block];
}

static inline FKFuture * FKFailure(FKFutureFailureBlock block) {
  return [FKFuture futureWithFailureBlock:block];
}

