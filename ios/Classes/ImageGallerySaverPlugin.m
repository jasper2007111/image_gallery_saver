#import "ImageGallerySaverPlugin.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

@implementation ImageGallerySaverPlugin {
    FlutterResult _result;
    NSDictionary *_arguments;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:@"image_gallery_saver"
                                   binaryMessenger:[registrar messenger]];
  ImageGallerySaverPlugin* instance = [ImageGallerySaverPlugin new];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (_result) {
        _result([FlutterError errorWithCode:@"multiple_request"
                                    message:@"Cancelled by a second request"
                                    details:nil]);
        _result = nil;
    }

    if ([@"saveImageToGallery" isEqualToString:call.method]) {
        _result = result;
        _arguments = call.arguments;

        FlutterStandardTypedData* fileData = (FlutterStandardTypedData*) _arguments;

        NSString * fileName = @"";
        //NSLog(@"fileData.data.length  :%ul",fileData.data.length);
        UIImage *image=[UIImage imageWithData:fileData.data];

        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusRestricted) {
            NSLog(@"not allow to access photo library");
        } else if (status == PHAuthorizationStatusDenied) { // if user chosen"Not Allow"
            NSLog(@"提Remind users to go to [Settings - Privacy - Photo - xxx] to open the access switch");
        } else if (status == PHAuthorizationStatusAuthorized) { // if user chosen"Allow"
            [self saveImage:image];
        } else if (status == PHAuthorizationStatusNotDetermined) { // if user not chosen before
            // Requests authorization with dialog
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) { //  if user  chosen "Allow"
                    //Save Image to Directory
                    [self saveImage:image];
                }
            }];
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)saveImage:(UIImage *)image  {
    __block NSString* fileName;
    __block NSString* localId;
    __block PHAssetChangeRequest *assetChangeRequest = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];


        // [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];

        localId = [[assetChangeRequest placeholderForCreatedAsset] localIdentifier];
    } completionHandler:^(BOOL success, NSError *error) {

        if (success) {
            NSLog(@"save image successful ");
            PHFetchResult* assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil];
            PHAsset *asset = [assetResult firstObject];
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                NSLog(@"Success %@ %@",dataUTI,info);

                NSLog(@"Success PHImageFileURLKey %@  ", (NSString *)[info objectForKey:@"PHImageFileURLKey"]);
                fileName=((NSURL *)[info objectForKey:@"PHImageFileURLKey"]).absoluteString;
                _result(fileName);
            }];

        } else {
            NSLog(@"save image failed!%@",error);

            fileName= @"";
            _result(fileName);

        }
    }];
}

@end
