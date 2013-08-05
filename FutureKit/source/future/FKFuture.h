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

-(FKFuture *)resolve;
-(FKFuture *)resolve:(id)object;

-(FKFuture *)error;
-(FKFuture *)error:(NSError *)error;

@property (readwrite, retain) FKFuture            * then;
@property (readwrite, copy)   FKFutureSuccessBlock  success;
@property (readwrite, copy)   FKFutureFailureBlock  failure;
@property (readonly, getter=isResolved) BOOL        resolved;
@property (readwrite, assign) BOOL                  forwardAfterError;

@end

static inline FKFuture * FKSuccess(FKFutureSuccessBlock block) {
  return [FKFuture futureWithSuccessBlock:block];
}

static inline FKFuture * FKFailure(FKFutureFailureBlock block) {
  return [FKFuture futureWithFailureBlock:block];
}

static inline FKFuture * FKFailureForward(FKFutureFailureBlock block) {
  FKFuture *future = [FKFuture futureWithFailureBlock:block];
  future.forwardAfterError = TRUE;
  return future;
}

