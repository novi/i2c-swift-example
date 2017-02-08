//
//  Slack.swift
//  AirPressureSensSlackPost
//
//  Created by Yusuke Ito on 2/8/17.
//  Copyright © 2017 Yusuke Ito. All rights reserved.
//

import Foundation
import CoreFoundation

#if UseSlackKit && Xcode
    typealias SlackWebAPI = WebAPI
#endif

#if UseSlackKit
import SlackKit
    
#else
    
internal extension String {
    
    var slackFormatEscaping: String {
        var escapedString = replacingOccurrences(of: "&", with: "&amp;")
        escapedString = replacingOccurrences(of: "<", with: "&lt;")
        escapedString = replacingOccurrences(of: ">", with: "&gt;")
        return escapedString
    }
    
    #if os(macOS)
    func urlQueryEscaped() -> String {
        var queryCharset = CharacterSet()
        queryCharset.insert(charactersIn: "a"..."z")
        queryCharset.insert(charactersIn: "-_.!~*'()")
        queryCharset.insert(charactersIn: "A"..."Z")
        queryCharset.insert(charactersIn: "0"..."9")
        return addingPercentEncoding(withAllowedCharacters: queryCharset)!
        // // not working on Swift ARM ???
    }
    #else
    
    func cfString() -> CFString {
        let selfData = self.data(using: .utf16)!
        return selfData.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) in
        CFStringCreateWithBytes(nil, bytes, selfData.count, CFStringEncoding(kCFStringEncodingUTF16), true)
        })
    }
    
    func urlQueryEscaped() -> String {
        let outStr = CFURLCreateStringByAddingPercentEscapes(nil, self.cfString(), nil, "!*'();:@&=+$,/?%#[]".cfString(), CFStringEncoding(kCFStringEncodingUTF8))
        let outCFData = CFStringCreateExternalRepresentation(nil, outStr, CFStringEncoding(kCFStringEncodingUTF16), 0)
        let outData = Data(bytes: CFDataGetBytePtr(outCFData), count: CFDataGetLength(outCFData))
        return String(data: outData, encoding: .utf16)!
    }
    #endif
}
 
final class SlackWebAPI {
    
    let token: String
    init(token: String) {
        self.token = token
    }
    
    enum SlackError: Error {
        case requestError(Error)
        case responseDataError
    }
    
    private static let session = URLSession(configuration: URLSessionConfiguration.default)
    
    private func sendRequest(api: String, parameters: [String:String], success: @escaping (([String:Any])->Void), failure: ((SlackError) -> Void)?) {
        var url = URLComponents(string: "https://slack.com/api/\(api)")!
        
        /*url.queryItems = [
         URLQueryItem(name: "token", value: token),
         URLQueryItem(name: "channel", value: channel),
         URLQueryItem(name: "text", value: text.slackFormatEscaping),
         ]*/ // not working on Swift ARM?
        
        var queryItems = [
            URLQueryItem(name: "token", value: token)
        ]
        for (k, v) in parameters {
            queryItems.append(URLQueryItem(name: k, value: v))
        }
        
        url.percentEncodedQuery = queryItems.map({ item in
            let value = item.value?.urlQueryEscaped()
            return value == nil ? item.name : "\(item.name)=\(value!)"
        }).joined(separator: "&")
        
        print(url.url!.absoluteString)
        var req = URLRequest(url: url.url!)
        req.httpMethod = "POST"
        let task = SlackWebAPI.session.dataTask(with: req, completionHandler: { (data_, res, err) in
            if let error = err {
                failure?(.requestError(error))
                return
            }
            guard let data = data_ else {
                failure?(.responseDataError)
                return
            }
            guard let resp = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                failure?(.responseDataError)
                return
            }
            success(resp)
            return
        })
        task.resume()
    }
    
    func sendMessage(channel: String, text: String, success: (((ts: String?, channel: String?))->Void)?, failure: ((SlackError) -> Void)?) {
        sendRequest(api: "chat.postMessage",
                    parameters: [ "channel": channel,
                                  "text": text.slackFormatEscaping
            ],
                    success: { (res) in
                        success?(res["ts"] as? String, res["channel"] as? String)
        }, failure: failure)
    }
    
}
#endif

