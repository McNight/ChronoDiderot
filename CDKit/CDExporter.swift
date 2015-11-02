//
//  CDExporter.swift
//  ChronoDiderot
//
//  Created by McNight on 26/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Foundation
import EventKit

public enum CDExporterResult {
	case NothingSpecial
	case SuccessCreate
	case SuccessUpdate
	case FailureCreate
	case FailureUpdate
	case CalendarNotCreated
	case CalendarNotFound
}

public class CDExporter {
	// Phase de tests avec le framework EventKit (que je ne connais pas...)
	private let eventStore = EKEventStore()
	
	public init() {
	}
	
	public func requestAuthorization(completionHandler: (authorized: Bool, error: NSError?) -> Void) {
		self.eventStore.requestAccessToEntityType(.Event) { success, error in
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler(authorized: success, error: error)
			}
		}
	}
	
	public func resetCalendarContext() -> Bool {
		let result = self.removeCalendar()
		
		CDHelpers.sharedHelper.setEventsParsedDate(nil)
		CDHelpers.sharedHelper.storeEventsParsedCount(-1)
		
		return result
	}
	
	public func renameCalendar() {
		guard let calendarIdentifier = CDHelpers.sharedHelper.customCalendarIdentifier() else {
			print("No Identifier Found...")
			return
		}
		
		guard let calendar = self.eventStore.calendarWithIdentifier(calendarIdentifier) else {
			print("Could not get Calendar with this identifier")
			return
		}
		
		let calendarName = CDHelpers.sharedHelper.preferredCalendarName()
		
		calendar.title = calendarName!
		
		do {
			try self.eventStore.saveCalendar(calendar, commit: true)
			CDHelpers.sharedHelper.storeCustomCalendarIdentifier(calendar.calendarIdentifier)
		} catch _ {
			print("Error saving calendar")
		}
	}
	
    public func createCalendar() {
		let calendarName = CDHelpers.sharedHelper.preferredCalendarName()
		
        let calendar = EKCalendar(forEntityType: .Event, eventStore: self.eventStore)
		calendar.title = calendarName == nil ? "Emploi du temps Diderot" : calendarName!
		
        let source = self.eventStore.defaultCalendarForNewEvents.source
        
        calendar.source = source
        
        do {
            try self.eventStore.saveCalendar(calendar, commit: true)
            CDHelpers.sharedHelper.storeCustomCalendarIdentifier(calendar.calendarIdentifier)
            CDHelpers.sharedHelper.setCustomCalendarCreated(true)
        } catch _ {
            print("Error saving calendar")
        }
    }
	
	private func removeCalendar() -> Bool {
		guard let calendarIdentifier = CDHelpers.sharedHelper.customCalendarIdentifier() else {
			print("No Identifier Found...")
			return false
		}
		
		guard let calendar = self.eventStore.calendarWithIdentifier(calendarIdentifier) else {
			print("Could not get Calendar with this identifier")
			return false
		}
		
		do {
			try self.eventStore.removeCalendar(calendar, commit: true)
			CDHelpers.sharedHelper.storeCustomCalendarIdentifier(nil)
			return true
		} catch _ {
			print("Error removing calendar")
			return false
		}
	}
    
    /// TODO: Better Error Handling...
	public func createOrUpdateEvents(events: [CDEvent]) -> CDExporterResult {
        guard CDHelpers.sharedHelper.customCalendarCreated() == true else {
            print("Calendar not created...")
            return .CalendarNotCreated
        }
		
		guard let calendarIdentifier = CDHelpers.sharedHelper.customCalendarIdentifier() else {
			print("No Identifier Found...")
			return .CalendarNotFound
		}
		
		guard let calendar = self.eventStore.calendarWithIdentifier(calendarIdentifier) else {
			print("Could not get the calendar with this identifier...")
			return .CalendarNotFound
		}
		
		// On va comparer le numéro de la semaine de l'année de la date courante par rapport à celle que l'on a précédemment stockée.
		// S'ils différent, c'est qu'on entame une nouvelle semaine et qu'il faut créer de nouveaux événements.
		// À l'inverse, s'ils sont identiques, alors c'est qu'on a relancé le processus et qu'il faut mettre à jour les événements déjà crées
		// en les récupérant à l'aide de leurs identifiants uniques (crées par le framework)
		
		var createMode = false
		var eventsIdentifiers: [String]!
		
		let currentDate = NSDate()
		let components = NSCalendar.currentCalendar().components([.WeekOfYear, .Weekday], fromDate: currentDate)
		var weekOfYearToCompare = components.weekOfYear
		
		if components.weekday == 1 || components.weekday == 7{
			weekOfYearToCompare += 1
		}
		
		let lastEventsParsedWeek = CDHelpers.sharedHelper.eventsParsedWeek()
		
		if lastEventsParsedWeek == -1 || (lastEventsParsedWeek != weekOfYearToCompare) {
			createMode = true
			CDHelpers.sharedHelper.setEventsParsedDate(currentDate)
			eventsIdentifiers = [String]()
		} else {
			eventsIdentifiers = CDHelpers.sharedHelper.eventsParsedIdentifiers()
		}
		
		print("Create Mode : \(createMode)")
		
		let locationWanted = CDHelpers.sharedHelper.userWantsLocation()
		
        for (index,data) in events.enumerate() {
			var event: EKEvent!
			
			if createMode {
				event = EKEvent(eventStore: self.eventStore)
			} else {
				event = self.eventStore.eventWithIdentifier(eventsIdentifiers[index])

				// On ne sait jamais...
				if event == nil {
					event = EKEvent(eventStore: self.eventStore)
				}
			}
			
			event.title = data.humanReadableTitle()
			event.startDate = data.beginDate
			event.endDate = data.endDate
			event.location = locationWanted == true ? data.location : nil
            event.calendar = calendar
			
            do {
				// Au départ, j'avais mis false pour commit
				// Mais si on ne fait que saveEvent, on ne peut pas accéder au eventIdentifier...
                try self.eventStore.saveEvent(event, span: .ThisEvent, commit: true)
				
				print("Event saved and commited !")
				
				if createMode {
					eventsIdentifiers.append(event.eventIdentifier)
				}
            } catch _ {
				print("Error saving Event")
				return createMode ? .FailureCreate : .FailureUpdate
            }
		}
		
		CDHelpers.sharedHelper.storeEventsParsedIdentifiers(eventsIdentifiers)
		
		return createMode ? .SuccessCreate : .SuccessUpdate
	}
}