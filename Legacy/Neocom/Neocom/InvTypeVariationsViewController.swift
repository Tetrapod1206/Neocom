//
//  InvTypeVariationsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import CoreData

enum InvTypeVariationsViewControllerInput {
	case objectID(NSManagedObjectID)
}

class InvTypeVariationsViewController: TreeViewController<InvTypeVariationsPresenter, InvTypeVariationsViewControllerInput>, TreeView {

	override func treeController<T>(_ treeController: TreeController, configure cell: UITableViewCell, for item: T) where T : TreeItem {
		super.treeController(treeController, configure: cell, for: item)
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.accessoryType = .disclosureIndicator
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
}

