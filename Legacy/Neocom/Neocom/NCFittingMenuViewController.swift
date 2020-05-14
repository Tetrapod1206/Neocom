//
//  NCFittingMenuViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingMenuContainerViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		childViewControllers.first?.addObserver(self, forKeyPath: "toolbarItems", options: [], context: nil)
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	deinit {
		childViewControllers.first?.removeObserver(self, forKeyPath: "toolbarItems")
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "toolbarItems" {
			toolbarItems = (object as? UIViewController)?.toolbarItems
		}
		else {
			return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		for controller in childViewControllers {
			controller.setEditing(editing, animated: animated)
		}
	}
}

class NCFittingMenuViewController: NCPageViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()

		viewControllers = [storyboard!.instantiateViewController(withIdentifier: "NCFittingShipsViewController"),
		                   storyboard!.instantiateViewController(withIdentifier: "NCFittingStructuresViewController"),
		                   storyboard!.instantiateViewController(withIdentifier: "NCFittingFleetsViewController"),
		                   storyboard!.instantiateViewController(withIdentifier: "NCFittingInGameFittingsViewController")
		]
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		for controller in viewControllers ?? [] {
			controller.setEditing(editing, animated: animated)
		}
		navigationController?.setToolbarHidden(!editing, animated: animated)
	}
	
}
