//
//  MyURLConnection.m
//  httpdns_api_demo
//
//  Created by DaveLam on 16/6/5.
//  Copyright © 2016年 com.aliyun.mobile. All rights reserved.
//

#import "NSURLConnection+HttpsExtension.h"

@implementation NSURLConnection(HttpsExtension)

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    /*
     * 创建证书校验策略
     */
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    
    /*
     * 绑定校验策略到服务端的证书上
     */
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    
    
    /*
     * 评估当前serverTrust是否可信任，
     * 官方建议在result = kSecTrustResultUnspecified 或 kSecTrustResultProceed
     * 的情况下serverTrust可以被验证通过，https://developer.apple.com/library/ios/technotes/tn2232/_index.html
     * 关于SecTrustResultType的详细信息请参考SecTrust.h
     */
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}
/*
 * NSURLConnection
 */
- (void)hda_connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!challenge) {
        return;
    }
    
    /*
     * URL里面的host在使用HTTPDNS的情况下被设置成了IP，此处从HTTP Header中获取真实域名
     */
//    NSString* host = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
//    if (!host) {
//        host = self.request.URL.host;
//    }
    NSString* host=@"www.aliyun.com";
    
    
    /*
     * 判断challenge的身份验证方法是否是NSURLAuthenticationMethodServerTrust（HTTPS模式下会进行该身份验证流程），
     * 在没有配置身份验证方法的情况下进行默认的网络请求流程。
     */
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host]) {
            /*
             * 验证完以后，需要构造一个NSURLCredential发送给发起方
             */
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        } else {
            /*
             * 验证失败，取消这次验证流程
             */
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    } else {
        /*
         * 对于其他验证方法直接进行处理流程
         */
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

@end
