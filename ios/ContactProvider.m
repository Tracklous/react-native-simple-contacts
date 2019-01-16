
//  ContactProvider.m
//  BigDataVoice
//
//  Created by Luc Belliveau on 2017-05-07.
//  Copyright © 2017 Luc Belliveau. All rights reserved.
//

//#import <UIKit/UIKit.h>
#import <Contacts/Contacts.h>
#import "ContactProvider.h"

@implementation NSObject (BVJSONString)

-(NSString*) bv_jsonStringWithPrettyPrint:(BOOL) prettyPrint {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
@end


@implementation ContactProvider

- (BOOL) prepareContacts
{
    if ([CNContactStore class]) {
        self.contacts = [[NSMutableArray alloc] init];
        //ios9 or later
        CNEntityType entityType = CNEntityTypeContacts;
        if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined)
        {
            CNContactStore *contactStore = [[CNContactStore alloc] init];
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(granted){
                    [self getAllContact];
                }
            }];
        }else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusRestricted
                 || [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusDenied ){
            return NO;
            //            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"ORB"
            //                                                                           message:@"This is an alert."
            //                                                                    preferredStyle:UIAlertControllerStyleAlert];
            //
            //            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Open" style:UIAlertActionStyleDefault
            //                                                                  handler:^(UIAlertAction * action) {[[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];}];
            //
            //            [alert addAction:defaultAction];
            //            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
            
            
        }
        else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusAuthorized)
        {
            [self getAllContact];
        }
    }
    return YES;
}

-(void)getAllContact
{
    if([CNContactStore class])
    {
        //iOS 9 or later
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataAvailableKey, CNContactThumbnailImageDataKey];
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        [addressBook enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
            
            for (CNLabeledValue<CNPhoneNumber*>* number in contact.phoneNumbers) {
                // if ([number.label isEqualToString:CNLabelPhoneNumberMobile]) {
                
                NSString *displayName = [contact.givenName stringByAppendingString:@" "];
                displayName = [displayName stringByAppendingString:contact.familyName];
                
                NSString *name = [displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSMutableDictionary *user = [NSMutableDictionary new];
                NSString *mobileNumber = @"";
                NSString *countryCodeString = @"";
                NSString *contactId = @"";
                
                if(name.length>0){
                    [user setValue:name forKey:@"name"];
                }else{
                    [user setValue:number.value.stringValue forKey:@"name"];
                }
                mobileNumber = [[number.value.stringValue componentsSeparatedByCharactersInSet:
                                 [[NSCharacterSet characterSetWithCharactersInString : @"+1234567890"] invertedSet]]
                                componentsJoinedByString:@""];
                
                contactId = [NSString stringWithFormat: @"%@_%@", contact.identifier, number.identifier];
                [user setValue:contactId forKey:@"key"];
                
                //          break;
                //        } else if ([mobileNumber isEqualToString:@""]) {
                //          mobileNumber =  [[number valueForKey:@"value"] valueForKey:@"digits"];
                //        }
                
                NSLocale *countryLocale = [NSLocale currentLocale];
                NSString *countryCode = [countryLocale objectForKey:NSLocaleCountryCode];
                NSString *country = [countryLocale displayNameForKey:NSLocaleCountryCode value:countryCode];
                NSLog(@"Country Code:%@ Name:%@", countryCode, country);
                
                
                if (mobileNumber.length > 0){
                    if ([mobileNumber hasPrefix:@"0"] ){
                        countryCodeString = [countryCode stringByAppendingString: @"-"];
                        mobileNumber = [countryCodeString stringByAppendingString: mobileNumber];
                    }
                    else if(![mobileNumber hasPrefix:@"+"]){
                            //mobileNumber = [NSString stringWithFormat:countryCode, mobileNumber];
                            //mobileNumber = [countryCode stringByAppendingString: mobileNumber];
                            countryCodeString = [countryCode stringByAppendingString: @"-"];
                            mobileNumber = [countryCodeString stringByAppendingString: mobileNumber];
                        }
                }
                
                [user setValue:mobileNumber forKey:@"number"];
                [user setValue:@"" forKey:@"code"];
                if (contact.imageDataAvailable) {
                    NSString *avatar = @"data:image/png;base64,";
                    [user setValue:[avatar stringByAppendingString:[contact.thumbnailImageData base64EncodedStringWithOptions:0]] forKey:@"avatar"];
                }
                [self.contacts addObject:user];
            }
        }];
    }
    
}

@end
