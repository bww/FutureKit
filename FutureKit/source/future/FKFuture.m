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
  if(self.success){
    FKFuture *chain;
    if((chain = self.success(object)) != nil){
      chain.then = self.then;
      self.then = chain;
    }
  }else if(self.then){
    [self.then resolve:object];
  }
}

-(void)error:(NSError *)error {
  if(self.failure) self.failure(error);
  else if(self.then) [self.then error:error];
}

-(FKFuture *)then:(FKFutureSuccessBlock)success, ... {
  FKFuture *current = nil;
  if(success){
    va_list ap;
    va_start(ap, success);
    FKFuture *next;
    
    next = [FKFuture futureWithSuccessBlock:success];
    self.then = next;
    current = next;
    
    FKFutureSuccessBlock block;
    while((block = va_arg(ap, FKFutureSuccessBlock)) != NULL){
      next = [FKFuture futureWithSuccessBlock:block];
      current.then = next;
      current = next;
    }
    
    va_end(ap);
  }
  return current;
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

