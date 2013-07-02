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
@synthesize perform = _perform;
@synthesize failure = _failure;

+(FKFuture *)future {
  return [[[self alloc] init] autorelease];
}

+(FKFuture *)futureWithPerformBlock:(FKFuturePerformBlock)perform {
  return [[[self alloc] initWithPerformBlock:perform] autorelease];
}

+(FKFuture *)futureWithFailureBlock:(FKFutureFailureBlock)failure {
  return [[[self alloc] initWithFailureBlock:failure] autorelease];
}

+(FKFuture *)futureWithPerformBlock:(FKFuturePerformBlock)perform failureBlock:(FKFutureFailureBlock)failure {
  return [[[self alloc] initWithPerformBlock:perform failureBlock:failure] autorelease];
}

-(void)dealloc {
  [_then release];
  [_perform release];
  [_failure release];
  [super dealloc];
}

-(id)init {
  return [self initWithPerformBlock:nil failureBlock:nil];
}

-(id)initWithPerformBlock:(FKFuturePerformBlock)perform {
  return [self initWithPerformBlock:perform failureBlock:nil];
}

-(id)initWithFailureBlock:(FKFutureFailureBlock)failure {
  return [self initWithPerformBlock:nil failureBlock:failure];
}

-(id)initWithPerformBlock:(FKFuturePerformBlock)perform failureBlock:(FKFutureFailureBlock)failure {
  if((self = [super init]) != nil){
    _perform = [perform copy];
    _failure = [failure copy];
  }
  return self;
}

-(void)resolve {
  [self resolve:nil];
}

-(void)resolve:(id)object {
  if(self.perform){
    id result;
    if((result = self.perform(object)) != nil){
      if([result isKindOfClass:[FKFuture class]]){
        ((FKFuture *)result).then = self.then; self.then = (FKFuture *)result;
      }else if([result isKindOfClass:[NSError class]]){
        [self error:(NSError *)result];
      }
    }
  }else if(self.then){
    [self.then resolve:object];
  }
}

-(void)error:(NSError *)error {
  if(self.failure) self.failure(error);
  else if(self.then) [self.then error:error];
}

-(FKFuture *)then:(FKFuturePerformBlock)perform, ... {
  FKFuture *current = nil;
  if(perform){
    va_list ap;
    va_start(ap, perform);
    FKFuture *next;
    
    next = [FKFuture futureWithPerformBlock:perform];
    self.then = next;
    current = next;
    
    FKFuturePerformBlock block;
    while((block = va_arg(ap, FKFuturePerformBlock)) != NULL){
      next = [FKFuture futureWithPerformBlock:block];
      current.then = next;
      current = next;
    }
    
    va_end(ap);
  }
  return current;
}

-(NSString *)description {
  
  NSString *this;
  if(self.perform && self.failure){
    this = [NSString stringWithFormat:@"<FKFuture (perform=%@, failure=%@)>", self.perform, self.failure];
  }else if(self.perform){
    this = [NSString stringWithFormat:@"<FKFuture (perform=%@)>", self.perform];
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

