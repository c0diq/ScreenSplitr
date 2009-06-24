/*

File: Bonjour.h
Abstract: A Wrapper that advertises http server port.

*/

#import <Foundation/Foundation.h>

//CLASSES:

@class Advertiser;

//ERRORS:

extern NSString * const AdvertiserErrorDomain;

//PROTOCOLS:

@protocol AdvertiserDelegate <NSObject>
@optional
- (void) serverDidEnableBonjour:(Advertiser*)advertiser withName:(NSString*)name;
- (void) server:(Advertiser*)advertiser didNotEnableBonjour:(NSDictionary *)errorDict;
@end

//CLASS INTERFACES:

@interface Advertiser : NSObject {
@private
	id _delegate;
    uint16_t _port;
	NSNetService* _netService;
}
	
- (BOOL)start:(uint16_t)port;
- (BOOL)stop;
- (BOOL) enableBonjourWithDomain:(NSString*)domain applicationProtocol:(NSString*)protocol name:(NSString*)name path:(NSString*)path; //Pass "nil" for the default local domain - Pass only the application protocol for "protocol" e.g. "myApp"
- (void) disableBonjour;

@property(assign) id<AdvertiserDelegate> delegate;

+ (NSString*) bonjourTypeFromIdentifier:(NSString*)identifier;

@end
