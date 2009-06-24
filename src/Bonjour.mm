/*

File: Bonjour.m
*/

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>
#import  <Foundation/NSRunLoop.h>
#import "Bonjour.h"

NSString * const AdvertiserErrorDomain = @"AdvertiserErrorDomain";

@interface Advertiser ()
@property(nonatomic,retain) NSNetService* netService;
@property(assign) uint16_t port;
@end

@implementation Advertiser

@synthesize delegate=_delegate, netService=_netService, port=_port;

- (id)init {
    return self;
}

- (void)dealloc {
    [self stop];
    [super dealloc];
}

- (BOOL)start:(uint16_t)port {
	self.port = port;
    return YES;
}

- (BOOL)stop {
    [self disableBonjour];

    return YES;
}

- (BOOL) enableBonjourWithDomain:(NSString*)domain applicationProtocol:(NSString*)protocol name:(NSString*)name path:(NSString*)path
{
	if(![domain length])
		domain = @""; //Will use default Bonjour registration doamins, typically just ".local"
	if(![name length])
		name = @""; //Will use default Bonjour name, e.g. the name assigned to the device in iTunes
	
	if(!protocol || ![protocol length] || !path || ![path length])
		return NO;
	
	self.netService = [[NSNetService alloc] initWithDomain:domain type:protocol name:name port:self.port];
	if(self.netService == nil)
		return NO;
	
	[self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.netService publish];
	[self.netService setDelegate:self];
	        
    // update root path
    NSDictionary* txtRecordDataDictionary = [NSDictionary dictionaryWithObject:@"/content/home.html" forKey:@"path"];
    [self.netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecordDataDictionary]];

	return YES;
}

/*
 Bonjour will not allow conflicting service instance names (in the same domain), and may have automatically renamed
 the service if there was a conflict.  We pass the name back to the delegate so that the name can be displayed to
 the user.
 See http://developer.apple.com/networking/bonjour/faq.html for more information.
 */

- (void)netServiceDidPublish:(NSNetService *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(serverDidEnableBonjour:withName:)])
		[self.delegate serverDidEnableBonjour:self withName:sender.name];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	[super netServiceDidPublish:sender];
	if(self.delegate && [self.delegate respondsToSelector:@selector(server:didNotEnableBonjour:)])
		[self.delegate server:self didNotEnableBonjour:errorDict];
}

- (void) disableBonjour
{
	if(self.netService) {
		[self.netService stop];
		[self.netService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		self.netService = nil;
	}
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = 0x%08X | port %d | netService = %@>", [self class], (long)self, self.port, self.netService];
}

+ (NSString*) bonjourTypeFromIdentifier:(NSString*)identifier {
	if (![identifier length])
		return nil;
    
    return [NSString stringWithFormat:@"_%@._tcp.", identifier];
}

@end
