//
//  CDModel.swift
//  ChronoDiderot
//
//  Created by McNight on 26/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Foundation

let CDKnownLocations = [ "4C", "4E", "10E", "12E" ]

public enum CDEventType {
	case Undefined
	case Cours
	case TD
}

public func eventTypeForString(type: String) -> CDEventType {
	switch type {
	case "COURS", "Cours", "cours":
		return .Cours
	case "TD", "Td", "td":
		return .TD
	default:
		return .Undefined
	}
}

public struct CDEvent {
	let type: CDEventType
	let name: String
	let beginDate: NSDate
	let endDate: NSDate
	let duration: Int
    let location: String?
	
	public func humanReadableTitle() -> String {
		return "\(type) de \(name)"
	}

	public func description() -> String {
		return "\(type) de \(name) le \(beginDate) jusqu'à \(endDate) (durée : \(duration)min)"
	}
    
    public func identifier() -> String {
        return "\(CDHelpers.dateFormatter.stringFromDate(beginDate))/\(type)/\(name)/\(duration)"
    }
}