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
  [_performError release];
  if(_semaphore) dispatch_release(_semaphore);
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

-(void)__perform {
  __block FKFuturePerformState state;
  
  // our completion block. this is invoked at the end of the process, either after waiting or performing.
  // we obtain our perform state again, which at this point must be either kFKFuturePerformStateSuccess
  // or kFKFuturePerformStateFailure, and take an appropriate action.
  
  void (^complete)(void) = ^ {
    
    @synchronized(self){
      // note the current state of resoltuion
      state = _performState;
      // update it to resolved (which we will do below)
      _performState = kFKFuturePerformStateResolved;
    }
    
    switch(state){
      case kFKFuturePerformStateResolved:
        // do nothing; we're already resolved
        break;
      case kFKFuturePerformStateSuccess:
        [self resolve];
        break;
      case kFKFuturePerformStateFailure:
        [self error:_performError];
        break;
      default:
        NSLog(@"* * * INVALID PERFORM STATE FOR FUTURE: %d", state);
        break;
    }
    
  };
  
  // determine if we have begun performing this future or not. this method is invoked when
  // the future attempts to resolve itself via -resolve. it's possible, however, that whatever
  // mechanism produced this future started its work in advance for pipelining (or other)
  // reasons. in this case, we don't want to start that work again, but rather wait for it to
  // finish, if necessary, and then propagate its result. we begin by checking the perform
  // state to determine how we should proceed.
  
  @synchronized(self){
    if((state = _performState) == kFKFuturePerformStateNotStarted){
      // create a semaphore used to coordinate future invocations
      if(_semaphore == NULL) _semaphore = dispatch_semaphore_create(0);
      // update the state for subsequent invocations
      _performState = kFKFuturePerformStateWorking;
    }
  }
  
  // if the performer is working, we wait for it to complete in our semaphore. if it is not
  // yet started, we peform it, and then signal any waiting threads. if it has already started
  // and completed, we don't do anything and just check the result.
  
  if(state == kFKFuturePerformStateWorking){
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    complete();
  }else if(state == kFKFuturePerformStateNotStarted){
    
    // perform our block, which should do whatever work it needs to and then invoke our callback
    self.perform(^(NSError *error) {
        
      @synchronized(self){
        // note our perform state, which is either success or failure
        _performState = (error == nil) ? kFKFuturePerformStateSuccess : kFKFuturePerformStateFailure;
        // if an error was produced, note that as well
        if(error) _performError = [error retain];
      }
      
      // finish performing
      complete();
      // signal any waiting threads that the future has resolved
      if(_semaphore) dispatch_semaphore_signal(_semaphore);
      
    });
    
  }
  
}

-(void)__resolve {
  if(self.success) self.success();
  if(self.then) [self.then resolve];
}

-(void)resolve {
  if(self.perform) [self __perform];
  else [self __resolve];
}

-(void)error:(NSError *)error {
  if(self.failure) self.failure(error);
  else if(self.then) [self.then error:error];
}

-(FKFuture *)then {
  @synchronized(self){
    return _then;
  }
}

-(void)setThen:(FKFuture *)then {
  @synchronized(self){
    if(_then) _then.then = then;
    else      _then = [then retain];
  }
}

-(NSString *)description {
  @synchronized(self){
    
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
}

@end

