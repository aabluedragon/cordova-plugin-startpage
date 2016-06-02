#import "StartPagePlugin.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "MainViewController.h"
#import "XMLParser.h"

/// NSUserDefaults
#define kStartPage @"StartPage"
#define kContentSrc @"widget.content.src"

/// config.xml
#define kIncludeVersionInStartPageUrl @"IncludeVersionInStartPageUrl"

/// keys for version in startPage Url (query param):
#define kNativeVersion @"nativeVersion"
#define kNativeBuild @"nativeBuild"

BOOL shouldAddVersionToUrl = NO;
CDVViewController *cdvViewController = nil;

NSString* addVersionToUrlIfRequired(NSString* page) {
    if(shouldAddVersionToUrl) {
        NSString *queryParamPrefix =
        ([page containsString:@"="] && [page containsString:@"?"])?
        @"&":@"?";

        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];

        NSString *CFBundleShortVersionString = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
        NSString *CFBundleVersion = [bundleInfo objectForKey:(NSString *)kCFBundleVersionKey];

        page = [NSString stringWithFormat:@"%@%@%@=%@&%@=%@",
                page, queryParamPrefix, kNativeVersion, CFBundleShortVersionString, kNativeBuild, CFBundleVersion];
    }
    return page;
}

@implementation StartPagePlugin

- (void)pluginInitialize {

}

/// Note(alonam):
/// -------------
/// We use this tricky way of loading the url because the "page" string param
/// may either represent an html that is part of this bundle, or a remote url with http://balbal/something.html
/// cordova already knows how to load it smartly, using the function CDVViewController.appUrl,
/// however, it's a private function of cordova, so we do this trick:
- (void)loadPageSmartly:(NSString*)page {
    // Because it's a private function in cordova, we invoke it this way:
    cdvViewController.startPage = page;
    NSURL* url = [cdvViewController performSelector:@selector(appUrl)];
    [(UIWebView*)self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark -
#pragma mark Cordova Commmands

- (void)setStartPageUrl:(CDVInvokedUrlCommand *)command {

    NSString *startPageUrl = [command.arguments objectAtIndex:0];
    if(startPageUrl) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:startPageUrl forKey:kStartPage];
        [defaults synchronize];

        [self.commandDelegate sendPluginResult: [CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                    callbackId: command.callbackId];
    } else {
        [self.commandDelegate sendPluginResult: [CDVPluginResult
                                                 resultWithStatus: CDVCommandStatus_ERROR
                                                 messageAsString:  @"bad_url"]
                                    callbackId: command.callbackId];
    }
}

- (void)loadStartPage:(CDVInvokedUrlCommand *)command {

    NSString *startPage = addVersionToUrlIfRequired([[NSUserDefaults standardUserDefaults] objectForKey:kStartPage]);
    [self loadPageSmartly:startPage];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)loadContentSrc:(CDVInvokedUrlCommand *)command {

    NSString *contentSrc = addVersionToUrlIfRequired([[NSUserDefaults standardUserDefaults] objectForKey:kContentSrc]);
    [self loadPageSmartly:contentSrc];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)resetStartPageToContentSrc:(CDVInvokedUrlCommand *)command {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kContentSrc] forKey:kStartPage];
    [defaults synchronize];

    [self.commandDelegate sendPluginResult: [CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId: command.callbackId];
}

@end

#pragma mark -
#pragma mark StartPage Setter Category

@implementation CDVAppDelegate (New)

- (void)bootstrap {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // parse config.xml
    NSString *configXmlPath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"xml"];
    NSString *configXml = [NSString stringWithContentsOfFile:configXmlPath encoding:NSUTF8StringEncoding error:nil];
    NSError *error = nil;
    NSDictionary *dict = [XMLParser dictionaryForXMLString:configXml error:&error];
    NSDictionary *widgetRoot = [dict objectForKey:@"widget"];

    // parse widget.content.src
    NSString *contentSrc = [[widgetRoot objectForKey:@"content"] objectForKey:@"src"];

    // read old widget.content.src
    NSString *oldContentSrc = [defaults objectForKey:kContentSrc];

    NSString *launchUrl = [defaults objectForKey:kStartPage];
    if([contentSrc isEqual:oldContentSrc] && launchUrl) {
        self.viewController.startPage = launchUrl;
    } else {
        self.viewController.startPage = contentSrc;
        [defaults setObject:contentSrc forKey:kStartPage];
        [defaults setObject:contentSrc forKey:kContentSrc];
        [defaults synchronize];
    }

    // Check if we need to include version in the url as query params, read from config.xml
    NSArray *preferences = [widgetRoot objectForKey:@"preference"];
    NSUInteger preferencesCount = [preferences count];
    shouldAddVersionToUrl = NO;
    for (NSUInteger i=0; i<preferencesCount; i++) {
        NSDictionary *pref = [preferences objectAtIndex:i];
        if([[pref objectForKey:@"name"] isEqual:kIncludeVersionInStartPageUrl]) {
            NSString *value = [pref objectForKey:@"value"];
            if([value isEqualToString:@"true"]) {
                shouldAddVersionToUrl = YES;
            }
        }
    }

    self.viewController.startPage = addVersionToUrlIfRequired(self.viewController.startPage);
    cdvViewController = self.viewController;
}

- (BOOL)newApplication:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    [self bootstrap];
    BOOL retVal = [self newApplication:application didFinishLaunchingWithOptions:launchOptions];
    return retVal;
}

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:)), class_getInstanceMethod(self, @selector(newApplication:didFinishLaunchingWithOptions:)));
}

@end
