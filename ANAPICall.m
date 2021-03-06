//
//  ANAPICall.m
//  AppApp
//
//  Created by Zach Holmquist on 8/10/12.
//  Copyright (c) 2012 Sneakyness. All rights reserved.
//

#import "ANAPICall.h"
#import "ANConstants.h"
#import "UIImage+SDExtensions.h"

@interface ANAPICall()
{
    id delegate;
    NSString *accessToken;
    NSString *userID;
}
-(void)readTokenFromDefaults;

@end

@implementation ANAPICall

+ (ANAPICall *)sharedAppAPI
{
    static dispatch_once_t oncePred;
    static ANAPICall *sharedInstance = nil;
    dispatch_once(&oncePred, ^{
        sharedInstance = [[[self class] alloc] initWithSpecification:@"ANAPI"];
    });
    return sharedInstance;
}

- (id)initWithSpecification:(NSString *)specificationName
{
    self = [super initWithSpecification:specificationName];
    
    // do some stuff here later.
    
    return self;
}

- (BOOL)hasAccessToken
{
    [self readTokenFromDefaults];
    if (accessToken && self.userID)
        return YES;
    return NO;
}


// validates whether the token is valid by requesting info about our user.
- (BOOL)isAccessTokenValid
{
    // our variable for an answer:
    BOOL answer;

    
    // Building a url request to handle "get user" query.  The method apart is
    // async and we need to get this info before we take any other action.
    NSString *urlString = [NSString stringWithFormat:@"http://alpha-api.app.net/stream/0/users/%@?access_token=%@", self.userID, accessToken];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    // filling in the blanks for the things we need to make this request
    // synchronous.
    NSError *error;
    NSURLResponse *response;
    
    // request the data and check to see if we have an error.
    NSData *json = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    
    // TODO: Implement better error handling here.
    if (error) {
        NSLog(@"error: %@", error);
    }
    
    // Process the data into a dictionary of json data and grab the error code
    // component if it exists.
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:json
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
    NSNumber *code = [[data objectForKey:@"error"] objectForKey:@"code"];
    
    // validate the code if it exists
    if ([code isEqualToNumber:[NSNumber numberWithInt:401]]) {
        
        // got the unauthorized client code.  kill the access token and return
        // NO as the answer.
        accessToken = nil;
        answer = NO;
        
    } else {
        
        // we're cool.  return YES
        answer = YES;
        
    }
    
    return answer;
}


// TODO: redo these later..
- (void)readTokenFromDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"access_token"];
    accessToken = token;
}

- (NSString *)userID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *idValue = [defaults objectForKey:@"userID"];
    return idValue;
}

- (SDWebServiceDataCompletionBlock)defaultJSONProcessingBlock
{
    // refactor SDWebService so error's are passed around properly. -- BKS
    
    SDWebServiceDataCompletionBlock result = ^(int responseCode, NSString *response, NSError *error) {
        NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        id dataObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        return dataObject;
    };
    return result;
}

- (void)makePostWithText:(NSString*)text uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    if (!accessToken)
        return;
    
    // App.net guys (? Alex K. and Mathew Phillips) say we should put accessToken in the headers, like so:
    // "Authorization: Bearer " + access_token
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"text" : text };
    
    [self performRequestWithMethod:@"postToStream" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)makePostWithText:(NSString*)text replyToPostID:(NSString *)postID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    if (!accessToken)
        return;
    
    // App.net guys (? Alex K. and Mathew Phillips) say we should put accessToken in the headers, like so:
    // "Authorization: Bearer " + access_token
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"text" : text, @"post_id" : postID };
    
    [self performRequestWithMethod:@"postToStreamAsReply" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];    
}

- (void)getGlobalStream:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken };
    
    [self performRequestWithMethod:@"getGlobalStream" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getGlobalStreamSincePost:(NSString*)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"since_id" : since_id };
    
    [self performRequestWithMethod:@"getGlobalStreamSince" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getGlobalStreamBeforePost:(NSString*)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"before_id" : before_id };
    
    [self performRequestWithMethod:@"getGlobalStreamBefore" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getTaggedPosts:(NSString*)hashtag withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"hashtag" : hashtag};
    
    [self performRequestWithMethod:@"getTaggedPosts" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getTaggedPosts:(NSString*)hashtag sincePost:(NSString*)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"since_id" : since_id, @"hashtag" : hashtag };
    
    [self performRequestWithMethod:@"getTaggedPostsSince" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getTaggedPosts:(NSString*)hashtag beforePost:(NSString*)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"before_id" : before_id, @"hashtag" : hashtag };
    
    [self performRequestWithMethod:@"getTaggedPostsBefore" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserStream:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken };
    
    [self performRequestWithMethod:@"getUserStream" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserStreamSincePost:(NSString*)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"since_id" : since_id };
    
    [self performRequestWithMethod:@"getUserStreamSince" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserStreamBeforePost:(NSString*)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"before_id" : before_id };
    
    [self performRequestWithMethod:@"getUserStreamBefore" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserPosts:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"getUserPosts" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserPosts:(NSString *)ID SincePost:(NSString*)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID, @"since_id" : since_id };
    
    [self performRequestWithMethod:@"getUserPostsSince" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserPosts:(NSString *)ID BeforePost:(NSString*)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID, @"before_id" : before_id };
    
    [self performRequestWithMethod:@"getUserPostsBefore" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserPosts:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self getUserPosts:self.userID uiCompletionBlock:uiCompletionBlock];
}

- (void)getUserPostsSincePost:(NSString *)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self getUserPosts:self.userID SincePost:since_id withCompletionBlock:uiCompletionBlock];
}

- (void)getUserPostsBeforePost:(NSString *)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self getUserPosts:self.userID BeforePost:before_id withCompletionBlock:uiCompletionBlock];
}

- (void)getUserMentions:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"getUserMentions" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserMentions:(NSString *)ID SincePost:(NSString*)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID, @"since_id" : since_id };
    
    [self performRequestWithMethod:@"getUserMentionsSince" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserMentions:(NSString *)ID BeforePost:(NSString*)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID, @"before_id" : before_id };
    
    [self performRequestWithMethod:@"getUserMentionsBefore" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUserMentions:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self getUserMentions:self.userID uiCompletionBlock:uiCompletionBlock];
}

- (void)getUserMentionsSincePost:(NSString *)since_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self getUserMentions:self.userID SincePost:since_id withCompletionBlock:uiCompletionBlock];
}

- (void)getUserMentionsBeforePost:(NSString *)before_id withCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self getUserMentions:self.userID BeforePost:before_id withCompletionBlock:uiCompletionBlock];
}

- (void)getCurrentUser:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken };
    
    [self performRequestWithMethod:@"getCurrentUser" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getUser:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"getUser" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];    
}

- (void)getUserFollowers:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"getUserFollowers" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];    
}

- (void)getUserFollowing:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"getUserFollowing" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getPostReplies:(NSString *)postID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"post_id" : postID };
    
    [self performRequestWithMethod:@"getPostReplies" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)followUser:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    if (!accessToken)
        return;
    
    // App.net guys (? Alex K. and Mathew Phillips) say we should put accessToken in the headers, like so:
    // "Authorization: Bearer " + access_token
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"followUser" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)unfollowUser:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"unfollowUser" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)muteUser:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    if (!accessToken)
        return;
    
    // App.net guys (? Alex K. and Mathew Phillips) say we should put accessToken in the headers, like so:
    // "Authorization: Bearer " + access_token
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"muteUser" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)unmuteUser:(NSString *)ID uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken, @"user_id" : ID };
    
    [self performRequestWithMethod:@"unmuteUser" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

- (void)getMutedUsers:(SDWebServiceUICompletionBlock)uiCompletionBlock
{
    [self readTokenFromDefaults];
    
    if (!accessToken)
        return;
    
    NSDictionary *replacements = @{ @"accessToken" : accessToken};
    
    [self performRequestWithMethod:@"getMutedUsers" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
}

#pragma mark - Imgur upload

- (void)uploadImage:(UIImage *)image caption:(NSString *)caption uiCompletionBlock:(SDWebServiceUICompletionBlock)uiCompletionBlock;
{
    // this one is speshul.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // should do a image resize here too.
        UIImage *resizedImage = [image resizedImageToFitInSize:CGSizeMake(320, 480) scaleIfSmaller:YES];
        NSString *imageData = [resizedImage base64forImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *replacements = @{ @"apiKey" : kImgurAPIKey, @"caption" : caption, @"base64image" : imageData };
            
            [self performRequestWithMethod:@"imgurPhotoUpload" routeReplacements:replacements dataProcessingBlock:[self defaultJSONProcessingBlock] uiUpdateBlock:uiCompletionBlock shouldRetry:YES];
        });
    });
}

@end
