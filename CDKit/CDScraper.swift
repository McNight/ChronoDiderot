//
//  CDScraper.swift
//  ChronoDiderot
//
//  Created by McNight on 16/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import Kanna

public class CDScraper {
	// À supprimer plus tard (ou du moins à ne pas laisser ici dans le scraper)
	private var dateFormatter: NSDateFormatter {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = .ShortStyle
		dateFormatter.timeStyle = .ShortStyle
		return dateFormatter
	}
	
	private var eventsContainer = [CDEvent]()
	
	public init() {
	}
	
	public func startScrapingData(data: NSData, completionHandler: (events: [CDEvent]) -> Void) {
		if let doc = Kanna.HTML(html: data, encoding: NSUTF8StringEncoding)
		{
			self.eventsContainer.removeAll()
			
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
				// Si quelqu'un a une meilleure solution...
				let firstTrTbody = doc.body!.xpath("fieldset/table[position()=1]/tbody[position()=1]")
				
				// J'étais partit pour analyser le tableau avec 2 compteurs, un pour les lignes et un autre pour les colonnes
				// Afin de déduire, avec des maths incroyablement compliqués, le jour et l'heure des cours/TD.
				// Ça fonctionnait, mais parfois le nombre de cellules dans les lignes n'est pas régulier donc bon...
				// Finalement on va faire ça encore plus salement, en se basant sur les title des cellules...
				
				self.analyseLine(firstTrTbody.first!)
				
				for tr in firstTrTbody.first!.xpath("tr") {
					self.analyseLine(tr)
				}
				
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler(events: self.eventsContainer)
				}
			}
		}
	}
	
	private func analyseLine(node: XMLElement) {
		let cells = node.xpath("td")
		
		for node in cells {
			self.analyseCell(node)
		}
	}
	
	private func analyseCell(node: XMLElement) {
		guard let title = node["title"] else {
			return
		}
		
		// Format : COURS Formats de documents et XML (M1) : lundi 8h30 (durée : 2h)
		
		let titleSplitted = title.componentsSeparatedByString(":")
		let typeAndActivity = titleSplitted[0]
		let date = titleSplitted[1]
		
		let type = typeAndActivity.componentsSeparatedByString(" ")[0]
		var activity = typeAndActivity.substringWithRange(Range<String.Index>(start: type.endIndex, end: typeAndActivity.endIndex))
		activity = String(activity.characters.dropFirst().dropLast())
		
		let dateSplitted = date.componentsSeparatedByString(" ")
		let day = dateSplitted[1]
		let time = dateSplitted[2].componentsSeparatedByString("h")
		let hours = Int(time[0])
		var minutes = Int(time[1])
		
		if minutes == nil {
			minutes = 0
		}
		
		let durationUnformatted = node["rowspan"]
		let duration = Int(durationUnformatted!)! * 30
		
		let beginDate = self.constructBeginDate(day, hours: hours!, minutes: minutes!)
		let endDate = self.constructEndDate(beginDate, duration: duration)
		
        let possibleLocation = self.parseLocationWithTitle(node.text!)
    
		let eventType = eventTypeForString(type)
        let event = CDEvent(type: eventType, name: activity, beginDate: beginDate, endDate: endDate, duration: duration, location: possibleLocation)
        
		self.eventsContainer.append(event)
	}
	
	private func constructBeginDate(day: String, hours: Int, minutes: Int) -> NSDate {
		let calendar = NSCalendar.currentCalendar()
		let currentDate = NSDate()
		let components = calendar.components([.Weekday], fromDate: currentDate)
		
		let givenWeekday = self.weekDayForDay(day)
		
		var constructedDate = calendar.dateBySettingHour(hours, minute: minutes, second: 0, ofDate: currentDate, options: [])
		
		var amountOfDays = 0
		
		// Dimanche = 1... Font rien comme nous les ricains
		// Je sais pas exactement quand les emplois du temps sont rafraichis, ni même si ils changent chaque semaine
		// Mais disons que le samedi et le dimanche, on récupère les jours de la semaine suivante
		
		if components.weekday == 1 {
			amountOfDays = 1 + (givenWeekday - 2)
		}
		else if components.weekday == 7 {
			amountOfDays = 2 + (givenWeekday - 2)
		}
		else {
			amountOfDays = givenWeekday - components.weekday
		}
		
		constructedDate = calendar.dateByAddingUnit([.Day], value: amountOfDays, toDate: constructedDate!, options: [])
		
		return constructedDate!
	}

	private func constructEndDate(beginDate: NSDate, duration: Int) -> NSDate {
		return NSCalendar.currentCalendar().dateByAddingUnit([.Minute], value: duration, toDate: beginDate, options: [])!
	}
	
	private func weekDayForDay(day: String) -> Int {
		switch day {
		case "lundi":
			return 2
		case "mardi":
			return 3
		case "mercredi":
			return 4
		case "jeudi":
			return 5
		case "vendredi":
			return 6
		case "samedi":
			return 7
		case "dimanche":
			return 1
		default:
			return 0
		}
	}
    
    private func parseLocationWithTitle(var title: String) -> String? {
        // Méthode de parsing horrible mais bon on a pas le choix...
        // Et puis je suis fainéant
        
        let level = "M1"
        title = title.stringByReplacingOccurrencesOfString(level, withString: "")
        
        for knownLocation in CDKnownLocations {
            if title.containsString(knownLocation) {
                return "Amphi \(knownLocation)"
            }
        }
        
        // On a pas trouvé d'endroits connus, alors on va récupérer les nombres et vérifier qu'ils sont supérieurs à...
        // 1000 pour indiquer une salle
        
        let components = title.componentsSeparatedByString(" ")
        
        for item in components {
            let subcomponents = item.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            for subitem in subcomponents {
                if Int(subitem) >= 1000 {
                    return "Salle \(subitem)"
                }
            }
        }
        
        return nil
    }
}
