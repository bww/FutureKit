# Future Kit
Future Kit is an Objective-C implementation of *Futures* (or *Promises*, if you prefer).

A future is a placeholder object representing a long-running, asynchronous operation that will complete (or fail) at some point in the future. When the operation a future represents completes the future is *resolved*, and its success handler block is executed. If the operation fails, the future's failure handler block is executed.

If a future resolves successfully, the success handler block has the option to return another future. In this way a sequence of asynchronous operations can be linked together in a chain making them easier to understand and handle.

# Producing Futures
A method which performs a long-running, asynchronous operation can return a future representing that operation in place of parameter success and failure handler blocks.

When the operation completes, this method must resolve the future. Or, if the operation fails, it must propagate an error.

	-(FKFuture *)downloadContentsOfURL:(NSURL *)url {
		FKFuture *future = [FKFuture future];
		
		// let's say this method actually does the work of downloading the data
		[self actuallyDownloadContentsOfURL:url
			complete:^ (NSData *data) {
				[future resolve:data];
			}
			failure:^ (NSError *error) {
				[future error:error];
			}
		];
		
		return future;
	}

# Using Futures
The code invoking the long-running operation can then use the future to handle it once it completes or fails. Using futures, it's trivial to perform a number of such operations in a sequence:

	MyDownloader *downloader; // assume this exists
	FKFuture *future = [downloader downloadContentsOfURL:theFirstURL];
	
	// download the second URL when the first completes
	future.finally = FKSuccess(^ id (NSData *data) {
		// do somethign with the data…
		[downloader downloadContentsOfURL:theSecondURL];
	});
	
	// download the third URL when the second completes
	future.finally = FKSuccess(^ id (NSData *data) {
		// do somethign with the data…
		[downloader downloadContentsOfURL:theThirdURL];
	});
	
	// handle the data from the third URL and end the chain
	future.finally = FKSuccess(^ id (NSData *data) {
		// do somethign with the data…
		return nil; // ok, we're done
	});
	
	// the error handler will be invoked if any of the preceding operations fail
	future.finally = FKFailure(^ void (NSError *error) {
		NSLog(@"Oh no! %@", [error localizedDescription];
		// note that errors are not recoverable in Future Kit
	});

# Run loops and deferred resolution
Future Kit requires a run loop to work. Graphical OS X and iOS apps use run loops by default, so unless you're writing a command-line application, you're fine.

Future Kit uses the run loop to schedule future resolution and error propagation to be delivered at the beginning of the next iteration of the current loop. This means that when you call `-resolve:` or `-error:`, the future is not actually resolved *immediately*, but rather *very soon*.

Resolving futures and propagating errors in this way allows you to do very useful things like this:

	-(FKFuture *)someLongRunningMethod:(id)object {
		FKFuture * future = [FKFuture future];
		
		if(object == nil) [future error:/* an error */];
		
		/* ... do something useful here */
		
		return future;
	}

In the example above, if the error were propagated immediately when `-error:` is invoked, it would be done *before* the future is returned to the caller, which would make it impossible for the caller to handle an error of this sort.

By waiting until the next iteration of the run loop the caller has an opportunity to register an error handler block with the returned future before the error is actualy propagated and everything works as you would expect.
