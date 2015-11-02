//
//  CDHelpers.swift
//  ChronoDiderot
//
//  Created by McNight on 27/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Foundation

public class CDHelpers {
    static public let sharedHelper = CDHelpers()
	
	public let CDM1InformatiqueURL = "http://porrum.informatique.univ-paris-diderot.fr:8080/~ufr/UFR2015-2016/EDT/visualiserEmploiDuTemps.php?quoi=M1,1"
	
	private let CDPreferencesCalendarNameKey = "CDCustomCalendarNameKey"
	private let CDPreferencesLocationWantedKey = "CDPreferencesLocationWantedKey"
	
    private let CDCustomCalendarIdentifierKey = "CDCustomCalendarIdentifierKey"
    private let CDCustomCalendarCreatedKey = "CDCustomCalendarCreatedKey"

	private let CDEventsParsedDatekey = "CDEventsParsedDatekey"
	private let CDEventsParsedIdentifiersKey = "CDEventsParsedIdentifiersKey"
	private let CDEventsParsedEventsCountKey = "CDEventsParsedEventsCountKey"
	
	private let CDDownloadedDataHashKey = "CDDownloadedDataHashKey"
	
	private let CDTwitterAccessAskedKey = "CDTwitterAccessAskedKey"
	private let CDTwitterDoesUserFollowUsKey = "CDTwitterDoesUserFollowUsKey"
    
    private var userDefaults = NSUserDefaults.standardUserDefaults()
	
    static public var dateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter
    }
	
	// Il paraît que les "synchronize()" ne sont plus utiles...
	
	public func storePreferredCalendarName(name: String?) {
		if let name = name {
			self.userDefaults.setObject(name, forKey: self.CDPreferencesCalendarNameKey)
		} else {
			self.userDefaults.setObject("Emploi du temps Diderot", forKey: self.CDPreferencesCalendarNameKey)
		}
		self.userDefaults.synchronize()
	}
	
	public func preferredCalendarName() -> String? {
		return self.userDefaults.objectForKey(self.CDPreferencesCalendarNameKey) as? String
	}
	
	public func storeUserWantsLocation(locationWanted: Bool) {
		self.userDefaults.setBool(locationWanted, forKey: self.CDPreferencesLocationWantedKey)
		self.userDefaults.synchronize()
	}
	
	public func userWantsLocation() -> Bool {
		return self.userDefaults.boolForKey(self.CDPreferencesLocationWantedKey)
	}
    
    public func storeCustomCalendarIdentifier(identifier: String?) {
        self.userDefaults.setObject(identifier, forKey: self.CDCustomCalendarIdentifierKey)
        self.userDefaults.synchronize()
    }
    
    public func customCalendarIdentifier() -> String? {
        return self.userDefaults.objectForKey(self.CDCustomCalendarIdentifierKey) as? String
    }
    
    public func setCustomCalendarCreated(created: Bool) {
        self.userDefaults.setBool(created, forKey: self.CDCustomCalendarCreatedKey)
        self.userDefaults.synchronize()
    }
    
    public func customCalendarCreated() -> Bool {
        return self.userDefaults.boolForKey(self.CDCustomCalendarCreatedKey)
    }
	
	public func setEventsParsedDate(date: NSDate?) {
		if let date = date {
			let data = NSKeyedArchiver.archivedDataWithRootObject(date)
			self.userDefaults.setObject(data, forKey: self.CDEventsParsedDatekey)
		}
		else {
			self.userDefaults.setObject(nil, forKey: self.CDEventsParsedDatekey)
		}
		self.userDefaults.synchronize()
	}
	
	public func eventsParsedDate() -> NSDate? {
		guard let data = self.userDefaults.dataForKey(self.CDEventsParsedDatekey) else {
			return nil
		}

		let eventsParsedDate = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSDate
		return eventsParsedDate
	}
	
	public func eventsParsedWeek() -> Int {
		guard let date = self.eventsParsedDate() else {
			return -1
		}
		
		let components = NSCalendar.currentCalendar().components([.WeekOfYear], fromDate: date)
		return components.weekOfYear
	}
	
	public func storeEventsParsedIdentifiers(identifiers: [String]) {
		let data = NSKeyedArchiver.archivedDataWithRootObject(identifiers)
		self.userDefaults.setObject(data, forKey: self.CDEventsParsedIdentifiersKey)
		self.userDefaults.synchronize()
	}
	
	public func eventsParsedIdentifiers() -> [String] {
		let data = self.userDefaults.dataForKey(self.CDEventsParsedIdentifiersKey)
		let identifiers = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! [String]
		return identifiers
	}
	
	public func storeEventsParsedCount(count: Int) {
		self.userDefaults.setInteger(count, forKey: self.CDEventsParsedEventsCountKey)
		self.userDefaults.synchronize()
	}
	
	public func eventsParsedCount() -> Int {
		let count = self.userDefaults.integerForKey(self.CDEventsParsedEventsCountKey)
		return count == 0 ? -1 : count
	}
	
	public func downloadedDataHash() -> String? {
		if let hash = self.userDefaults.objectForKey(self.CDDownloadedDataHashKey) as? String {
			return hash
		}
		return nil
	}
	
	public func setDownloadedDataHash(hash: String) {
		self.userDefaults.setObject(hash, forKey: self.CDDownloadedDataHashKey)
		self.userDefaults.synchronize()
	}
	
	public func twitterAccessAsked() -> Bool {
		return self.userDefaults.boolForKey(self.CDTwitterAccessAskedKey)
	}
	
	public func setTwitterAccessAsked(accessAsked: Bool) {
		self.userDefaults.setBool(accessAsked, forKey: self.CDTwitterAccessAskedKey)
		self.userDefaults.synchronize()
	}
	
	public func doesUserFollowUs() -> Bool {
		return self.userDefaults.boolForKey(self.CDTwitterDoesUserFollowUsKey)
	}
	
	public func setUserFollowUs(follow: Bool) {
		self.userDefaults.setBool(follow, forKey: self.CDTwitterDoesUserFollowUsKey)
		self.userDefaults.synchronize()
	}
}
