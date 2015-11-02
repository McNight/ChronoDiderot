//
//  EDTViewController.swift
//  ChronoDiderot
//
//  Created by McNight on 16/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import UIKit
import CDKit
import SVProgressHUD

extension NSData {
	func sha1() -> String {
		var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
		CC_SHA1(self.bytes, CC_LONG(self.length), &digest)
		let hexBytes = digest.map { String(format: "%02hhx", $0) }
		return hexBytes.joinWithSeparator("")
	}
}

class EDTViewController: UITableViewController {
	@IBOutlet weak var lastImportationCell: UITableViewCell!
	@IBOutlet weak var numberOfEventsCell: UITableViewCell!
	
	@IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		let exporter = CDExporter()
		exporter.requestAuthorization { authorized, error in
			if authorized {
				if CDHelpers.sharedHelper.customCalendarCreated() == false {
					exporter.createCalendar()
				}
			}
			else {
				SVProgressHUD.showErrorWithStatus("Erreur lors de l'authorisation... \(error?.localizedDescription)")
			}
		}
		
    }
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		self.updateUserInterface()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func launchDownloadAndImportation() {
		SVProgressHUD.setDefaultMaskType(.Gradient)
		SVProgressHUD.showWithStatus("Téléchargement en cours...")
		
		let downloader = CDDownloader()
		downloader.startDownload { formerData -> Void in
			if let data = formerData
			{
				SVProgressHUD.showWithStatus("Importation en cours...")
				
				let hash = data.sha1()
				
				if let previousHash = CDHelpers.sharedHelper.downloadedDataHash() where previousHash == hash {
					if let lastParsedDate = CDHelpers.sharedHelper.eventsParsedDate() where
						NSCalendar.currentCalendar().isDate(lastParsedDate, inSameDayAsDate: NSDate()) {
							SVProgressHUD.showInfoWithStatus("Rien n'a changé !")
							self.refreshBarButtonItem.enabled = true
							return
					}
				}
				
				CDHelpers.sharedHelper.setDownloadedDataHash(hash)
				
				let scraper = CDScraper()
				
				scraper.startScrapingData(data) { events in
					let numberOfEvents = events.count
					CDHelpers.sharedHelper.storeEventsParsedCount(numberOfEvents)
					
					let exporter = CDExporter()
					let exporterResult = exporter.createOrUpdateEvents(events)
					
					switch exporterResult {
					case .CalendarNotCreated, .CalendarNotFound:
						exporter.createCalendar()
						exporter.createOrUpdateEvents(events)
						SVProgressHUD.showSuccessWithStatus("Événements importés avec succès !")
					case .FailureCreate:
						SVProgressHUD.showErrorWithStatus("Erreur lors de la création des événements")
					case .FailureUpdate:
						SVProgressHUD.showErrorWithStatus("Erreur lors de la mise à jour des événements")
					case .SuccessCreate:
						SVProgressHUD.showSuccessWithStatus("Événements importés avec succès !")
					case .SuccessUpdate:
						SVProgressHUD.showSuccessWithStatus("Événements mis à jour avec succès !")
					case .NothingSpecial:
						SVProgressHUD.showInfoWithStatus("Ce message ne devrait pas s'afficher...")
					}
					
					self.updateUserInterface()
				}
			}
			else
			{
				SVProgressHUD.showErrorWithStatus("Une erreur est survenue...")
			}
		}
	}
	
	func updateUserInterface() {
		self.refreshBarButtonItem.enabled = true
		
		let lastParsedDate = CDHelpers.sharedHelper.eventsParsedDate()
		let eventsParsedCount = CDHelpers.sharedHelper.eventsParsedCount()
		
		let lastImportationCellText = lastParsedDate != nil ? CDHelpers.dateFormatter.stringFromDate(lastParsedDate!) : "Jamais"
		let numberOfEventsCellText = eventsParsedCount != -1 ? "\(eventsParsedCount) événéments" : "Aucun"
		
		self.lastImportationCell.detailTextLabel!.text = lastImportationCellText
		self.numberOfEventsCell.detailTextLabel!.text = numberOfEventsCellText
	}
	
	// MARK: - Actions
	
	@IBAction func refreshBarButtonItemPressed(sender: UIBarButtonItem) {
		sender.enabled = false
		
		self.launchDownloadAndImportation()
	}
	
	// MARK: - Table View Delegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 1 && indexPath.row == 0 {
			let URLString = CDHelpers.sharedHelper.CDM1InformatiqueURL
			let URL = NSURL(string: URLString)!
			
			UIApplication.sharedApplication().openURL(URL)
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
}
