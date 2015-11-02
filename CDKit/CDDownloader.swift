//
//  CDDownloader.swift
//  ChronoDiderot
//
//  Created by McNight on 16/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Foundation

public class CDDownloader {
	public init() {
	}
	
	public func startDownload(completionHandler: (data: NSData?) -> ()) {
		let URLString = CDHelpers.sharedHelper.CDM1InformatiqueURL
		let URL = NSURL(string: URLString)!
		
		let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
		let session = NSURLSession(configuration: sessionConfiguration)
		
		let downloadDataTask = session.dataTaskWithURL(URL) { (formerData, formerResponse, formerError) -> Void in
			if let error = formerError
			{
				print("Error : \(error.localizedDescription)")
				
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler(data: nil)
				}
			}
			else
			{
				let httpResponse = formerResponse as! NSHTTPURLResponse
				
				if httpResponse.statusCode == 200
				{
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler(data: formerData)
					}
				}
				else
				{   
					print("Status Code not 200 with response : \(httpResponse.description)")
					
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler(data: nil)
					}
				}
			}
		}
		
		downloadDataTask.resume()
	}
}
