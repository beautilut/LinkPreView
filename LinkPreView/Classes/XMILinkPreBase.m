//
//  XMILinkPreBase.m
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/30.
//

#import "XMILinkPreBase.h"

static dispatch_queue_t linkPreView_url_process_queue() {
    static dispatch_queue_t xmi_linkpreView_url_process_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xmi_linkpreView_url_process_queue = dispatch_queue_create("com.himalaya.networking.linkpreview.process", DISPATCH_QUEUE_CONCURRENT);
    });
    return xmi_linkpreView_url_process_queue;
}

static dispatch_group_t linkPreView_url_session_completion_group() {
    static dispatch_group_t xmi_linkpreview_url_session_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xmi_linkpreview_url_session_completion_group = dispatch_group_create();
    });
    return xmi_linkpreview_url_session_completion_group;
}


typedef void(^XMILinkTaskSessionCompletionHandler)(XMILinkPreObject * object , NSError * error);


@interface XMILinkTaskSessionDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic , weak) XMILinkPreBase * preBase;

@property (nonatomic , strong) NSMutableData * mutableData;
@property (nonatomic , strong) NSString * baseUrl;
@property (nonatomic , copy) XMILinkTaskSessionCompletionHandler completion;

-(instancetype)initWithTask:(NSURLSessionTask *)task;

@end

@implementation XMILinkTaskSessionDelegate

-(instancetype)initWithTask:(NSURLSessionTask *)task
{
    if (self = [super init]) {
        
        _mutableData = [NSMutableData data];
        
        [task resume];
        
    }
    return self;
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    __strong XMILinkPreBase * preBase = self.preBase;
    
    XMILinkPreObject * preObject = [[XMILinkPreObject alloc] init];
    preObject.baseUrl = self.baseUrl;
    
    NSData * data= nil;
    if (self.mutableData) {
        data = [self.mutableData copy];
        self.mutableData = nil;
    }
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completion) {
                self.completion(preObject, error);
            }
        });
    }else {
        
        dispatch_async(linkPreView_url_process_queue(), ^{
            NSError * serializationError = nil;
            
            [preBase.responseSerializer preObject:preObject withResponse:task.response data:data error:&serializationError];

            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.completion) {
                    self.completion(preObject, serializationError);
                }
            });
        });
    }
}

-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data];
}

@end

@interface XMILinkPreBase () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic , strong) NSMutableDictionary * taskDelegateDictionary;
@property (nonatomic , strong) NSLock * lock;

@property (nonatomic , strong) NSOperationQueue * operationQueue;
@property (nonatomic , strong) NSURLSession * session;

@end

@implementation XMILinkPreBase

+(XMILinkPreBase *)shareInstance
{
    static XMILinkPreBase * defaultPreBase;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultPreBase = [[XMILinkPreBase alloc] init];
    });
    return defaultPreBase;
}

-(instancetype)init
{
    if (self = [super init]) {
        
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        self.taskDelegateDictionary = [NSMutableDictionary dictionary];
        
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.operationQueue];
        
        self.responseSerializer = [[XMILinkSerializer alloc] init];
        
    }
    return self;
}

-(NSURLSessionTask *)extractUrlString:(NSString *)urlString onCompletion:(void(^)(XMILinkPreObject * object , NSError * error))completionHandler
{
    NSError * error;
    //过滤URL
    NSDataDetector * detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink  error:&error];
    NSTextCheckingResult * detectorMatch= [detector matchesInString:urlString options:0 range:NSMakeRange(0, urlString.length)].firstObject;
    
    NSString * url = [detectorMatch URL].absoluteString;
    
    NSURLRequest * request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLSessionDataTask * task = [self.session dataTaskWithRequest:request];
    
    [self addDelegateForDataTask:task baseUrl:url completionHandler:completionHandler];
    
    return task;
}

-(void)addDelegateForDataTask:(NSURLSessionTask *)dataTask baseUrl:(NSString *)baseUrl completionHandler:(void(^)(XMILinkPreObject * object , NSError * error))completionHandler
{
    XMILinkTaskSessionDelegate * delegate = [[XMILinkTaskSessionDelegate alloc] initWithTask:dataTask];
    delegate.preBase = self;
    delegate.baseUrl = baseUrl;
    delegate.completion = completionHandler;
    [self setDelegate:delegate forTask:dataTask];
}

-(void)setDelegate:(XMILinkTaskSessionDelegate *)delegate forTask:(NSURLSessionTask *)task
{
    [self.lock lock];
    self.taskDelegateDictionary[@(task.taskIdentifier)] = delegate;
    [self.lock unlock];
}

-(XMILinkTaskSessionDelegate *)delegateForTask:(NSURLSessionTask *)task {
    
    XMILinkTaskSessionDelegate * delegate = nil;
    
    [self.lock lock];
    delegate = self.taskDelegateDictionary[@(task.taskIdentifier)];
    [self.lock unlock];
    
    return delegate;
}

-(void)removeDelegateForTask:(NSURLSessionTask *)task
{
    [self.lock lock];
    
    [self.taskDelegateDictionary removeObjectForKey:@(task.taskIdentifier)];
    
    [self.lock unlock];
}

#pragma mark -- NSURLSessionDataDelegate --

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    XMILinkTaskSessionDelegate * delegate = [self delegateForTask:task];
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];
        
        [self removeDelegateForTask:task];
    }
}

-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data
{
    XMILinkTaskSessionDelegate * delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];
}

@end
