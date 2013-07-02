// 
// Copyright (c) 2013 Brian William Wolter. All rights reserved.
// 
// @LICENSE@
// 
// Developed in New York City
// 

typedef void (^FKFutureSuccessBlock)(void);
typedef void (^FKFutureFailureBlock)(NSError *error);
typedef void (^FKFutureResolveBlock)(NSError *error);
typedef void (^FKFuturePerformBlock)(FKFutureResolveBlock block);

typedef enum {
  kFKFuturePerformStateNotStarted = 0,
  kFKFuturePerformStateWorking,
  kFKFuturePerformStateSuccess,
  kFKFuturePerformStateFailure,
  kFKFuturePerformStateResolved
} FKFuturePerformState;

@interface FKFuture : NSObject {
@private
  dispatch_semaphore_t  _semaphore;
  FKFuturePerformState  _performState;
  NSError             * _performError;
}

+(FKFuture *)future;
+(FKFuture *)futureWithSuccessBlock:(FKFutureSuccessBlock)success;
+(FKFuture *)futureWithFailureBlock:(FKFutureFailureBlock)failure;
+(FKFuture *)futureWithSuccessBlock:(FKFutureSuccessBlock)success failureBlock:(FKFutureFailureBlock)failure;

-(id)initWithSuccessBlock:(FKFutureSuccessBlock)success;
-(id)initWithFailureBlock:(FKFutureFailureBlock)failure;
-(id)initWithSuccessBlock:(FKFutureSuccessBlock)success failureBlock:(FKFutureFailureBlock)failure;

-(void)resolve;
-(void)error:(NSError *)error;

@property (readwrite, retain) FKFuture            * then;
@property (readwrite, copy)   FKFutureSuccessBlock  success;
@property (readwrite, copy)   FKFutureFailureBlock  failure;
@property (readwrite, copy)   FKFuturePerformBlock  perform;

@end

static inline FKFuture * FKSuccess(FKFutureSuccessBlock block) {
  return [FKFuture futureWithSuccessBlock:block];
}

static inline FKFuture * FKFailure(FKFutureFailureBlock block) {
  return [FKFuture futureWithFailureBlock:block];
}

