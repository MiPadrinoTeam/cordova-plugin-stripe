#import <Cordova/CDV.h>
@import Stripe;

@interface CordovaStripe : CDVPlugin
@property(nonatomic, retain) STPAPIClient *client;

- (void)setPublishableKey:(CDVInvokedUrlCommand *)command;
- (void)createBankAccountToken:(CDVInvokedUrlCommand *)command;
- (void)createAccountToken:(CDVInvokedUrlCommand *)command;

@end
