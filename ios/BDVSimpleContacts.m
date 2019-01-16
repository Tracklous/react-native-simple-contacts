
#import "BDVSimpleContacts.h"
#import "ContactProvider.h"

@implementation BDVSimpleContacts

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getProfile:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    resolve([NSNumber numberWithInteger: 1]);
}

RCT_EXPORT_METHOD(findContactByNumber:(NSString*) number resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    resolve([NSNumber numberWithInteger: 1]);
}

RCT_EXPORT_METHOD(getContacts:(NSString*) timestamp resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    ContactProvider *cp = [ContactProvider new];
    BOOL value = [cp prepareContacts];
    if(value==NO)
    {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                                   };
        NSError *error = [NSError errorWithDomain:@"NSHipsterErrorDomain"
                                             code:201
                                         userInfo:userInfo];
        reject(@"201",@"permission denied", error);
    }else{
        resolve([cp.contacts bv_jsonStringWithPrettyPrint:false]);
    }
}

@end

