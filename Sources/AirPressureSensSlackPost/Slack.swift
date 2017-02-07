//
//  Slack.swift
//  AirPressureSensSlackPost
//
//  Created by Yusuke Ito on 2/8/17.
//  Copyright © 2017 Yusuke Ito. All rights reserved.
//

import Foundation

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
    
    func sendMessage(channel: String, text: String, success: (((ts: String?, channel: String?))->Void)?, failure: ((SlackError) -> Void)?) {
        var url = URLComponents(string: "https://slack.com/api/chat.postMessage")!
        url.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "channel", value: channel),
            URLQueryItem(name: "text", value: text.slackFormatEscaping),
        ]
        print(url.url!)
        var req = URLRequest(url: url.url!)
        req.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: req, completionHandler: { (data_, res, err) in
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
            success?(resp["ts"] as? String, resp["channel"] as? String)
            return
        })
        task.resume()
    }
    
}
#endif

