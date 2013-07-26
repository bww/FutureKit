// 
// Copyright 2013 Brian William Wolter, All rights reserved.
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 

#import "FKFuture.h"

@interface FKFuture (/* Private */)
@property (readwrite, retain) FKFuture * next;
@end

@implementation FKFuture

@synthesize next = _next;
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
  [_next release];
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
 * 
 * @return the receiver
 */
-(FKFuture *)resolve {
  return [self resolve:nil];
}

/**
 * Resolve this future. This method should be invoked when the long-running operation
 * represented by this future has completed successfully.
 * 
 * The future is resolved at the beginning of the next iteration of the run loop. This method
 * is intended to function essentially as does autorelease by providing enough time to pass
 * the future to another object before it is resolved.
 * 
 * @param object The result of the operation. This is the object provided to the success
 * handler block as a paramter.
 * @return the receiver
 */
-(FKFuture *)resolve:(id)object {
  [[NSRunLoop currentRunLoop] performSelector:@selector(__resolve:) target:self argument:object order:NSUIntegerMax modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
  return self;
}

/**
 * @internal
 * 
 * Resolve this future immediately. Unlike -resolve:, this method does not wait until
 * the next run loop iteration to resolve the future.
 * 
 * @param object The result of the operation. This is the object provided to the success
 * handler block as a paramter.
 */
-(void)__resolve:(id)object {
  id result = nil;
  
  // if this future is already resolved, we do nothing. this can occur when a future has been
  // resolved and a caller sends a second resolve message, which is incorrect.
  if(self.resolved) return;
  
  // invoke the success handler if we have one and handle the result. the handler may return
  // another future, in which case we link it into the chain, or an error, in which case we bail
  if(self.success){
    if((result = self.success(object)) != nil){
      if([result isKindOfClass:[FKFuture class]]){
        ((FKFuture *)result).next = self.next; self.next = (FKFuture *)result;
      }else if([result isKindOfClass:[NSError class]]){
        [self error:(NSError *)result];
      }
    }
  }
  
  // if the handler did not produce a result of some sort and we have a next future, just
  // forward the result to the next future in the chain. it may have more work to do
  if(result == nil && self.next){
    [self.next __resolve:object];
  }
  
  // mark this future as being resolved
  self.resolved = TRUE;
  
}

/**
 * Resolve this future with an unspecified error.
 * 
 * @return the receiver
 */
-(FKFuture *)error {
  return [self error:nil];
}

/**
 * Resolve this future with an error.
 * 
 * The future is resolved with an error at the beginning of the next iteration of the run loop.
 * This method is intended to function essentially as does autorelease by providing enough time
 * to pass the future to another object before it is resolved.
 * 
 * @param error The error produced by the operation. This is the object provided to the
 * failure handler block as a paramter.
 * @return the receiver
 */
-(FKFuture *)error:(NSError *)error {
  [[NSRunLoop currentRunLoop] performSelector:@selector(__error:) target:self argument:error order:NSUIntegerMax modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
  return self;
}

/**
 * @internal
 * 
 * Resolve this future with an error immediately. Unlike -error:, this method does not wait until
 * the next run loop iteration to resolve the future.
 * 
 * @param error The error produced by the operation. This is the object provided to the
 * failure handler block as a paramter.
 */
-(void)__error:(NSError *)error {
  
  // if this future is already resolved, we do nothing. this can occur when a future has been
  // resolved and a caller sends a second resolve message, which is incorrect.
  if(self.resolved) return;
  
  // handle the error either via the failure block, or by forwarding it to the next future in the chain.
  if(self.failure){
    self.failure(error);
  }else if(self.next){
    [self.next __error:error];
  }
  
  // mark this future and all futures remaining in this chain as resolved
  [self setResolvedForward:TRUE];
  
}

/**
 * Obtain the last future in this chain, which may be this future itself. This is <em>not</em> the
 * next future in the chain immediately following the receiver.
 */
-(FKFuture *)then {
  return (self.next) ? [self.next then] : self;
}

/**
 * Set the last future in this chain. Setting this property like so:
 * 
 *    future.then = another;
 * 
 * has the same effect as the following, but expressed more clearly:
 * 
 *    future.then.next = another;
 * 
 * This property is used to link futures into a chain by adding a future to the end. Futures
 * are always added to the end of a chain.
 */
-(void)setThen:(FKFuture *)future {
  self.then.next = future;
}

/**
 * Determine if this entire chain of futures is resolved.
 */
-(BOOL)isResolved {
  BOOL resolved;
  @synchronized(self){ resolved = _resolved; }
  if(resolved) return (self.next) ? [self.next isResolved] : TRUE;
  else return FALSE;
}

/**
 * Specify whether this future is resolved
 */
-(void)setResolved:(BOOL)resolved {
  @synchronized(self){ _resolved = resolved; }
}

/**
 * Mark this future and any forward futures in its chain as resolved
 */
-(void)setResolvedForward:(BOOL)resolved {
  self.resolved = resolved;
  if(self.next) [self.next setResolvedForward:resolved];
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
  
  if(self.next){
    return [NSString stringWithFormat:@"%@ then %@", this, self.next];
  }else{
    return [NSString stringWithFormat:@"%@", this];
  }
  
}

@end

