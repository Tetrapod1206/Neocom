//
//  NCDatabaseGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Futures

class NCDatabaseGroupRow: NCFetchedResultsObjectNode<NCDBInvGroup> {
	
	required init(object: NCDBInvGroup) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.compact.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.groupName
		cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCDatabaseGroupsViewController: NCTreeViewController, NCSearchableViewController {
	var category: NCDBInvCategory?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])

		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
		title = category?.categoryName
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let request = NSFetchRequest<NCDBInvGroup>(entityName: "InvGroup")
		request.sortDescriptors = [NSSortDescriptor(key: "published", ascending: false), NSSortDescriptor(key: "groupName", ascending: true)]
		request.predicate = NSPredicate(format: "category == %@ AND types.@count > 0", category!)
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "published", cacheName: nil)
		
		return .init(FetchedResultsNode(resultsController: results, sectionNode: NCDatabasePublishingSectionNode<NCDBInvGroup>.self, objectNode: NCDatabaseGroupRow.self))
	}
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseGroupRow else {return}
		Router.Database.Types(group: row.object).perform(source: self, sender: treeController.cell(for: node))
	}

	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, let category = category, text.count > 2 {
			predicate = NSPredicate(format: "group.category == %@ AND typeName CONTAINS[C] %@", category, text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}
