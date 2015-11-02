//
//  SettingsViewController.swift
//  ChronoDiderot
//
//  Created by McNight on 31/10/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import UIKit
import CDKit
import Accounts
import Social
import SVProgressHUD

class SettingsViewController: UITableViewController {

	@IBOutlet weak var calendarNameTextField: UITextField!
	@IBOutlet weak var locationWantedSwitch: UISwitch!
	
	@IBOutlet weak var twitterFollowCell: UITableViewCell!
	
	@IBOutlet weak var loveBarButtonItem: UIBarButtonItem!
	
	lazy var exporter = CDExporter()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.socialChecks()
		self.prepareUserInterface()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func prepareUserInterface() {
		self.calendarNameTextField.text = CDHelpers.sharedHelper.preferredCalendarName()
		self.locationWantedSwitch.on = CDHelpers.sharedHelper.userWantsLocation()
	}
	
	// MARK: - Preferences
	
	@IBAction func locationWantedValueChanged(sender: UISwitch) {
		CDHelpers.sharedHelper.storeUserWantsLocation(sender.on)
	}
	
	@IBAction func calendarNameValueChanged(sender: UITextField) {
		if sender.text?.isEmpty == false {
			CDHelpers.sharedHelper.storePreferredCalendarName(sender.text)
		} else {
			CDHelpers.sharedHelper.storePreferredCalendarName(nil)
		}
		self.exporter.renameCalendar()
	}
	
	@IBAction func deleteCurrentCalendarAction(sender: UIBarButtonItem) {
		let title = "Suppression du calendrier"
		let message = "Êtes-vous sûr de vouloir supprimer le calendrier actuel ? Tous les événements y associés seront supprimés."
		
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		
		let cancelAction = UIAlertAction(title: "Annuler", style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		let confirmAction = UIAlertAction(title: "Confirmer", style: .Destructive) { action in
			dispatch_async(dispatch_get_main_queue()) {
				SVProgressHUD.setDefaultMaskType(.Gradient)
				
				if self.exporter.resetCalendarContext() {
					SVProgressHUD.showSuccessWithStatus("Calendrier supprimé avec succès !")
				} else {
					SVProgressHUD.showErrorWithStatus("Erreur lors de la suppression...")
				}
			}
		}
		alertController.addAction(confirmAction)
		
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	// MARK: - Social Stuff
	
	@IBAction func loveButtonPressed(sender: UIBarButtonItem) {
		if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
			let tweetSheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
			
			tweetSheet.setInitialText("J'adore ChronoDiderot de @AdaMcNight :) /cc @ParisDiderot")
			
			self.presentViewController(tweetSheet, animated: true, completion: nil)
		} else {
			SVProgressHUD.showErrorWithStatus("Indisponible !")
		}
	}
	
	func socialChecks() {
		if CDHelpers.sharedHelper.twitterAccessAsked() {
			if CDHelpers.sharedHelper.doesUserFollowUs() {
				self.loveBarButtonItem.enabled = true
				self.twitterFollowCell.textLabel!.text = "Merci. Voir mes tweets !"
			}
			else {
				self.loveBarButtonItem.enabled = false
				self.twitterFollowCell.textLabel!.text = "Snif... Voir mes tweets quand même !"
			}
		}
		else {
			self.loveBarButtonItem.enabled = false
		}
	}
	
	// MARK: - Follow Twitter Stuff
	
	func twitterVerifications() {
		let account = ACAccountStore()
		let twitterAccountType = account.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
		
		account.requestAccessToAccountsWithType(twitterAccountType, options: nil) { (success, error) -> Void in
			CDHelpers.sharedHelper.setTwitterAccessAsked(true)
			
			if success {
				let allAcounts = account.accountsWithAccountType(twitterAccountType)
				
				if allAcounts.count > 0 {
					let twitterAccount = allAcounts.last as! ACAccount // On devrait plutôt afficher tous les comptes et laisser le user choisir
					
					self.doYouFollowVanadiumVerification(twitterAccount, completionHandler: { (follow) -> Void in
						CDHelpers.sharedHelper.setUserFollowUs(follow)
						
						if follow {
							dispatch_async(dispatch_get_main_queue()) {
								self.loveBarButtonItem.enabled = true
								self.twitterFollowCell.textLabel!.text = "Merci de me suivre sur Twitter !"
							}
						}
						else {
							self.followVanadium(twitterAccount)
						}
					})
				}
				else {
					print("Aucun compte Twitter !")
				}
			}
			else {
				print("Access denied !")
			}
		}
	}
	
	func doYouFollowVanadiumVerification(account: ACAccount, completionHandler: (follow: Bool) -> Void) {
		let paramsVerif = [  "screen_name" : "AdaMcNight" ]
		let requestURLVerif = NSURL(string: "https://api.twitter.com/1.1/users/show.json")
		
		let getRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: requestURLVerif, parameters: paramsVerif)
		
		getRequest.account = account
		
		getRequest.performRequestWithHandler { (data, response, error) -> Void in
			if let error = error {
				print("Error : \(error.localizedDescription)")
				
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler(follow: false)
				}
			}
			else {
				do {
					let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [String : AnyObject]
					let following = json["following"] as! Bool
					
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler(follow: following)
					}
				} catch let error as NSError {
					print("Error parsing : \(error.localizedDescription)")
					
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler(follow: false)
					}
				}
			}
		}
	}
	
	func followVanadium(account: ACAccount) {
		let params = [  "screen_name" : "AdaMcNight",
			"follow" : true]
		let requestURL = NSURL(string: "https://api.twitter.com/1.1/friendships/create.json")
		
		let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
			requestMethod: .POST, URL: requestURL, parameters: params)
		
		postRequest.account = account
		
		postRequest.performRequestWithHandler({ (data, response, error) -> Void in
			if let error = error
			{
				self.showErrorWithStatus("Oops... Erreur : \(error.localizedDescription)")
			}
			else
			{
				if response.statusCode == 200
				{
					self.showSuccessWithStatus("Merci !")
				}
				else
				{
					self.showErrorWithStatus("Oops... Erreur ! (Code \(response.statusCode))")
				}
			}
		})
	}
	
	private func showSuccessWithStatus(status: String) {
		CDHelpers.sharedHelper.setUserFollowUs(true)
		
		dispatch_async(dispatch_get_main_queue()) {
			SVProgressHUD.setDefaultMaskType(.Gradient)
			SVProgressHUD.showSuccessWithStatus(status)
			self.loveBarButtonItem.enabled = true
		}
	}
	
	private func showErrorWithStatus(status: String) {
		dispatch_async(dispatch_get_main_queue()) {
			SVProgressHUD.setDefaultMaskType(.Gradient)
			SVProgressHUD.showErrorWithStatus(status)
		}
	}
	
	// MARK: - Table View Delegate
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 2 && indexPath.row == 0
		{
			if CDHelpers.sharedHelper.twitterAccessAsked()
			{
				UIApplication.sharedApplication().openURL(NSURL(string: "https://twitter.com/adamcnight")!)
			}
			else
			{
				self.twitterVerifications()
			}
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
}
