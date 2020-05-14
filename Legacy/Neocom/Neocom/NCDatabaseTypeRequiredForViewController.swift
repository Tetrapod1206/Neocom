//
//  NCDatabaseTypeRequiredForViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Futures

class NCDatabaseTypeRequiredForViewController: NCTreeViewController {
	
	var type: NCDBInvType?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCModuleTableViewCell.default,
		                    Prototype.NCShipTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default,
		                    ])
		
	}
	
	override func content() -> Future<TreeNode?> {
		guard let type = type else {return .init(nil)}
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return .init(nil)}
		
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		
		request.predicate = NSPredicate(format: "ANY requiredSkills.skillType == %@", type)
		request.sortDescriptors = [
			NSSortDescriptor(key: "group.category.categoryName", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "group.category.categoryName", cacheName: nil)
		
		let root = FetchedResultsNode(resultsController: controller, sectionNode: NCDefaultFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCDatabaseTypeRow<NCDBInvType>.self)
		return .init(root)
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let node = node as? NCDatabaseTypeRow<NCDBInvType> else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
}
