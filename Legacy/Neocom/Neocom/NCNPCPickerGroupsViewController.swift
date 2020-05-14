//
//  NCNPCPickerGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Futures

class NCNPCPickerGroupsViewController: NCTreeViewController, NCSearchableViewController {
	
	var parentGroup: NCDBNpcGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		
		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCNPCPickerTypesViewController"))
		title = parentGroup?.npcGroupName ?? NSLocalizedString("NPC", comment: "")
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let request = NSFetchRequest<NCDBNpcGroup>(entityName: "NpcGroup")
		request.sortDescriptors = [NSSortDescriptor(key: "npcGroupName", ascending: true)]
		if let parent = parentGroup {
			request.predicate = NSPredicate(format: "parentNpcGroup == %@", parent)
		}
		else {
			request.predicate = NSPredicate(format: "parentNpcGroup == NULL")
		}
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		try? results.performFetch()
		
		return .init(FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCNPCGroupRow.self))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCNPCGroupRow else {return}
		if row.object.group != nil {
			Router.Database.NPCPickerTypes(npcGroup: row.object).perform(source: self, sender: treeController.cell(for: node))
		}
		else {
			Router.Database.NPCPickerGroups(parentGroup: row.object).perform(source: self, sender: treeController.cell(for: node))
		}
	}


	
	
	//MARK: UISearchResultsUpdating
	
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCNPCPickerTypesViewController else {return}
		if let text = searchController.searchBar.text, text.count > 2 {
			predicate = NSPredicate(format: "group.category.categoryID == 11 AND typeName CONTAINS[C] %@", text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}
