// 
// Copyright (c) 2013 Brian William Wolter. All rights reserved.
// 
// @LICENSE@
// 
// Developed in New York City
// 

#import "FKFuture.h"

@implementation FKFuture

@synthesize then = _then;
@synthesize success = _success;
@synthesize failure = _failure;
@synthesize resolved = _resolved;

+(FKFuture *)future {
  return [[[self alloc] init] autorelease];
}

+(FKFuture *)futureWithSuccessBlock:(FKFutureSuccessBlock)success {
  return [[[self alloc] initWithSuccessBlock:success] autorelease];
}

+(FKFuture *)futureWithFailureBlock:(FKFutureFailureBlock)failure {
  return [[[self alloc] initWithFailureBlock:failure] autorelease];
}

+(FKFuture *)futureWithSuccessBlock:(FKFutureSuccessBlock)success failureBlock:(FKFutureFailureBlock)failure {
  return [[[self alloc] initWithSuccessBlock:success failureBlock:failure] autorelease];
}

-(void)dealloc {
  [_then release];
  [_success release];
  [_failure release];
  [super dealloc];
}

-(id)init {
  return [self initWithSuccessBlock:nil failureBlock:nil];
}

-(id)initWithSuccessBlock:(FKFutureSuccessBlock)success {
  return [self initWithSuccessBlock:success failureBlock:nil];
}

-(id)initWithFailureBlock:(FKFutureFailureBlock)failure {
  return [self initWithSuccessBlock:nil failureBlock:failure];
}

-(id)initWithSuccessBlock:(FKFutureSuccessBlock)success failureBlock:(FKFutureFailureBlock)failure {
  if((self = [super init]) != nil){
    _success = [success copy];
    _failure = [failure copy];
  }
  return self;
}

/**
 * Resolve this future. This method should be invoked when the long-running operation
 * represented by this future has completed successfully.
 */
-(void)resolve {
  [self resolve:nil];
}

/**
 * Resolve this future. This method should be invoked when the long-running operation
 * represented by this future has completed successfully.
 * 
 * @param object The result of the operation. This is the object provided to the success
 * handler block as a paramter.
 */
-(void)resolve:(id)object {
  id result = nil;
  
  // invoke the success handler if we have one and handle the result. the handler may return
  // another future, in which case we link it into the chain, or an error, in which case we bail
  if(self.success){
    if((result = self.success(object)) != nil){
      if([result isKindOfClass:[FKFuture class]]){
        ((FKFuture *)result).then = self.then; self.then = (FKFuture *)result;
      }else if([result isKindOfClass:[NSError class]]){
        [self error:(NSError *)result];
      }
    }
  }
  
  // if the handler did not produce a result of some sort and we have a then future, just
  // forward the result to the next future in the chain. it may have more work to do
  if(result == nil && self.then){
    [self.then resolve:object];
  }
  
  // mark this future as being resolved
  @synchronized(self){ _resolved = TRUE; }
  
}

/**
 * Resolve this future with an error.
 */
-(void)error {
  [self error:nil];
}

/**
 * Resolve this future with an error.
 * 
 * @param error The error produced by the operation. This is the object provided to the
 * failure handler block as a paramter.
 */
-(void)error:(NSError *)error {
  
  // handle the error either via the failure block, or by forwarding it to the next future in the chain.
  if(self.failure){
    self.failure(error);
  }else if(self.then){
    [self.then error:error];
  }
  
  // mark this future as being resolved
  @synchronized(self){ _resolved = TRUE; }
  
}

/**
 * Set a number of futures in a chain, each with a success handler block, as the
 * next future after the receiver.
 */
-(FKFuture *)then:(FKFutureSuccessBlock)success, ... {
  FKFuture *current = nil;
  if(success){
    va_list ap;
    va_start(ap, success);
    current = [self then:success arguments:ap];
    va_end(ap);
  }
  return current;
}

/**
 * Set a number of futures in a chain, each with a success handler block, as the
 * next future after the receiver.
 */
-(FKFuture *)then:(FKFutureSuccessBlock)success arguments:(va_list)arguments {
  FKFuture *current = nil;
  FKFuture *next;
  
  next = [FKFuture futureWithSuccessBlock:success];
  self.then = next;
  current = next;
  
  FKFutureSuccessBlock block;
  while((block = va_arg(arguments, FKFutureSuccessBlock)) != NULL){
    next = [FKFuture futureWithSuccessBlock:block];
    current.then = next;
    current = next;
  }
  
  return current;
}

/**
 * Obtain the last future in this chain, which may be this future itself.
 */
-(FKFuture *)last {
  return (self.then) ? self.then.last : self;
}

/**
 * Determine if this entire chain of futures is resolved.
 */
-(BOOL)isResolved {
  BOOL resolved;
  @synchronized(self){ resolved = _resolved; }
  if(resolved) return (self.then) ? [self.then isResolved] : TRUE;
  else return FALSE;
}

/**
 * Obtain a string description
 */
-(NSString *)description {
  
  NSString *this;
  if(self.success && self.failure){
    this = [NSString stringWithFormat:@"<FKFuture (success=%@, failure=%@)>", self.success, self.failure];
  }else if(self.success){
    this = [NSString stringWithFormat:@"<FKFuture (success=%@)>", self.success];
  }else if(self.failure){
    this = [NSString stringWithFormat:@"<FKFuture (failure=%@)>", self.failure];
  }else{
    this = @"<FKFuture>";
  }
  
  if(self.then){
    return [NSString stringWithFormat:@"%@ then %@", this, self.then];
  }else{
    return [NSString stringWithFormat:@"%@", this];
  }
  
}

@end

