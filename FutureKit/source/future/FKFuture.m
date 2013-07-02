// 
// Copyright (c) 2013 Brian William Wolter. All rights reserved.
// 
// @LICENSE@
// 
// Developed in New York City
// 

#import "FKFuture.h"

@implementation FKFuture

@synthesize then    = _then;
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

-(void)resolve {
  [self resolve:nil];
}

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

-(void)error {
  [self error:nil];
}

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

-(BOOL)isResolved {
  BOOL resolved;
  @synchronized(self){ resolved = _resolved; }
  if(resolved) return (self.then) ? [self.then isResolved] : TRUE;
  else return FALSE;
}

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

