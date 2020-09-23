#import "CordovaStripe.h"
@import Stripe;

@implementation CordovaStripe

@synthesize client;

- (void)setPublishableKey:(CDVInvokedUrlCommand*)command
{

    NSString* publishableKey = [[command arguments] objectAtIndex:0];
    [[STPPaymentConfiguration sharedConfiguration] setPublishableKey:publishableKey];

    if (self.client == nil) {
        // init client if doesn't exist
        client = [[STPAPIClient alloc] init];
    } else {
        [self.client setPublishableKey:publishableKey];
    }

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

}

- (void)throwNotInitializedError:(CDVInvokedUrlCommand *) command
{
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"You must call setPublishableKey method before executing this command."];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void (^)(STPToken * _Nullable token, NSError * _Nullable error))handleTokenCallback: (CDVInvokedUrlCommand *) command
{
    return ^(STPToken * _Nullable token, NSError * _Nullable error) {
        CDVPluginResult* result;
        if (error != nil) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error.localizedDescription];
        } else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:token.allResponseFields];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    };
}


- (void) createBankAccountToken:(CDVInvokedUrlCommand *)command
{
    if (self.client == nil) {
        [self throwNotInitializedError:command];
        return;
    }


    [self.commandDelegate runInBackground:^{

        NSDictionary* const bankAccountInfo = [command.arguments objectAtIndex:0];
        STPBankAccountParams* params = [[STPBankAccountParams alloc] init];

        params.accountNumber = bankAccountInfo[@"account_number"];
        params.country = bankAccountInfo[@"country"];
        params.currency = bankAccountInfo[@"currency"];
        params.routingNumber = bankAccountInfo[@"routing_number"];
        params.accountHolderName = bankAccountInfo[@"account_holder_name"];

        NSString* accountType = bankAccountInfo[@"account_holder_type"];
        if ([accountType  isEqualToString: @"individual"]) {
            params.accountHolderType = STPBankAccountHolderTypeIndividual;
        } else if([accountType isEqualToString: @"company"]) {
            params.accountHolderType = STPBankAccountHolderTypeCompany;
        }

        [self.client createTokenWithBankAccount:params completion:[self handleTokenCallback:command]];

    }];

}


- (void) createAccountToken:(CDVInvokedUrlCommand *)command
{
    if (self.client == nil) {
        [self throwNotInitializedError:command];
        return;
    }


    [self.commandDelegate runInBackground:^{
        NSDictionary* const data = [command.arguments objectAtIndex:0];

        NSDictionary* const individual = data[@"individual"];
        NSDictionary* const _address = individual[@"address"];
        NSDictionary* const _dateOfBirth = individual[@"dob"];

        STPConnectAccountIndividualParams *individualParams = [STPConnectAccountIndividualParams new];
        STPConnectAccountAddress *address = [STPConnectAccountAddress new];
        NSDateComponents *dateOfBirth = [NSDateComponents new];

        dateOfBirth.day = [_dateOfBirth[@"day"] integerValue];
        dateOfBirth.month = [_dateOfBirth[@"month"] integerValue];
        dateOfBirth.year = [_dateOfBirth[@"year"] integerValue];


        address.city = _address[@"city"];
        address.country = _address[@"country"];
        address.line1 = _address[@"line1"];
        address.line2 = _address[@"line2"];
        address.postalCode = _address[@"postal_code"];
        address.state = _address[@"state"];


        individualParams.email = individual[@"email"];
        individualParams.firstName = individual[@"first_name"];
        individualParams.lastName = individual[@"last_name"];
        individualParams.gender = individual[@"gender"];
        individualParams.phone = individual[@"phone"];
        individualParams.ssnLast4 = individual[@"ssn_last_4"];
        individualParams.address = address;
        individualParams.dateOfBirth = dateOfBirth;

        STPConnectAccountParams *connectAccountParams = [[STPConnectAccountParams alloc] initWithTosShownAndAccepted:YES individual:individualParams];

        [self.client createTokenWithConnectAccount:connectAccountParams completion:[self handleTokenCallback:command]];
    }];
}

@end
