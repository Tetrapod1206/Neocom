//
//  NCFittingFleetMemberPickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import Dgmpp
import EVEAPI
import Futures

class NCFittingFleetMemberPickerViewController: NCTreeViewController {
	
	var completionHandler: ((NCFittingFleetMemberPickerViewController) -> Void)!
	var fleet: NCFittingFleet?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])

	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func content() -> Future<TreeNode?> {
		guard let fleet = fleet else {return .init(nil)}
		
		var sections = [TreeNode]()
		
		sections.append(DefaultTreeRow(image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("New Ship Fit", comment: ""), accessoryType: .disclosureIndicator, route: Router.Database.TypePicker(category: NCDBDgmppItemCategory.category(categoryID: .ship)!, completionHandler: {[weak self] (controller, type) in
			guard let strongSelf = self else {return}
			strongSelf.dismiss(animated: true)
			
			let typeID = Int(type.typeID)
			_ = try? fleet.append(typeID: typeID)
			strongSelf.completionHandler(strongSelf)
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
			
		})))
		
		let context = NCStorage.sharedStorage?.viewContext
		let filter = fleet.pilots.compactMap { (_, objectID) -> NCLoadout? in
			guard let objectID = objectID else {return nil}
			return context?.object(with: objectID) as? NCLoadout
		}
		let predicate = filter.count > 0 ? NSPredicate(format: "NONE SELF IN %@", filter) : nil
		
		
		sections.append(NCLoadoutsSection<NCLoadoutNoRouteRow>(categoryID: .ship, filter: predicate))
		return .init(RootNode(sections))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)

		if let node = node as? NCLoadoutRow {
			guard let fleet = fleet else {return}

			NCStorage.sharedStorage?.performBackgroundTask({ (managedObjectContext) in
				guard let loadout = (try? managedObjectContext.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
				_ = try? fleet.append(loadout: loadout)
				DispatchQueue.main.async {
					self.completionHandler(self)
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
				}
			})
		}
	}
	
}
