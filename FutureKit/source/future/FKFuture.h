// 
// Copyright (c) 2013 Brian William Wolter. All rights reserved.
// 
// @LICENSE@
// 
// Developed in New York City
// 

@class FKFuture;

typedef id    (^FKFuturePerformBlock)(id object);
typedef void  (^FKFutureFailureBlock)(NSError *error);

@interface FKFuture : NSObject

+(FKFuture *)future;
+(FKFuture *)futureWithPerformBlock:(FKFuturePerformBlock)perform;
+(FKFuture *)futureWithFailureBlock:(FKFutureFailureBlock)failure;
+(FKFuture *)futureWithPerformBlock:(FKFuturePerformBlock)perform failureBlock:(FKFutureFailureBlock)failure;

-(id)initWithPerformBlock:(FKFuturePerformBlock)perform;
-(id)initWithFailureBlock:(FKFutureFailureBlock)failure;
-(id)initWithPerformBlock:(FKFuturePerformBlock)perform failureBlock:(FKFutureFailureBlock)failure;

-(void)resolve;
-(void)resolve:(id)object;
-(void)error:(NSError *)error;

-(FKFuture *)then:(FKFuturePerformBlock)perform, ...;

@property (readwrite, retain) FKFuture            * then;
@property (readwrite, copy)   FKFuturePerformBlock  perform;
@property (readwrite, copy)   FKFutureFailureBlock  failure;

@end

static inline FKFuture * FKPerform(FKFuturePerformBlock block) {
  return [FKFuture futureWithPerformBlock:block];
}

static inline FKFuture * FKFailure(FKFutureFailureBlock block) {
  return [FKFuture futureWithFailureBlock:block];
}

