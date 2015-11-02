//
//  CreditsViewController.swift
//  ChronoDiderot
//
//  Created by McNight on 01/11/2015.
//  Copyright © 2015 McNight. All rights reserved.
//

import UIKit

class CreditsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.title = "Remerciements"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View Delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (0,0): // Kanna
			let KANNA_URL_STRING = "https://github.com/tid-kijyun/Kanna"
			let URL = NSURL(string: KANNA_URL_STRING)
			UIApplication.sharedApplication().openURL(URL!)
		case (0,1): // SVProgressHUD
			let SVPROGRESSHUD_URL_STRING = "https://github.com/TransitApp/SVProgressHUD"
			let URL = NSURL(string: SVPROGRESSHUD_URL_STRING)
			UIApplication.sharedApplication().openURL(URL!)
		case (1,0): // BraveBros
			let BRAVEBROS_URL_STRING = "https://thenounproject.com/bravebros/"
			let URL = NSURL(string: BRAVEBROS_URL_STRING)
			UIApplication.sharedApplication().openURL(URL!)
		case (1,1): // Anton Anderson
			let ANTON_URL_STRING = "https://thenounproject.com/nash101/"
			let URL = NSURL(string: ANTON_URL_STRING)
			UIApplication.sharedApplication().openURL(URL!)
		default:
			print("bruh")
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
}
