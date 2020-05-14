//
//  NCContactsSearchResultViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI


protocol NCContactsSearchResultViewControllerDelegate: NSObjectProtocol {
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: NCContact)
}

class NCContactsSearchResultViewController: NCTreeViewController {
	
	weak var delegate: NCContactsSearchResultViewControllerDelegate?
	
	var contacts: [NCContact] = [] {
		didSet {
			var names: [ESI.Mail.RecipientType: [NCContact]] = [:]
			
			for contact in contacts {
				guard let recipientType = contact.recipientType else {continue}
				var array = names[recipientType] ?? []
				array.append(contact)
				names[recipientType] = array
			}

			
			let dataManager = NCDataManager(account: NCAccount.current)
			let titles = [ESI.Mail.RecipientType.alliance: NSLocalizedString("Alliances", comment: "").uppercased(),
			              ESI.Mail.RecipientType.corporation: NSLocalizedString("Corporations", comment: "").uppercased(),
			              ESI.Mail.RecipientType.character: NSLocalizedString("Characters", comment: "").uppercased()]
			let identifiers = [ESI.Mail.RecipientType.character: "0",
			                   ESI.Mail.RecipientType.corporation: "1",
			                   ESI.Mail.RecipientType.alliance: "2"]
			var sections = [DefaultTreeSection]()
			for (key, value) in names {
				let rows = value.map { NCContactRow(contact: $0.objectID, dataManager: dataManager) }/*.sorted { ($0.contact?.name ?? "") < ($1.contact?.name ?? "") }*/
				let section = DefaultTreeSection(nodeIdentifier: identifiers[key], title: titles[key], children: rows)
				sections.append(section)
			}
			sections.sort { ($0.nodeIdentifier ?? "Z") < ($1.nodeIdentifier ?? "Z") }
			
			UIView.performWithoutAnimation {
				if let root = treeController?.content {
					root.children = sections
				}
				else {
					treeController?.content = RootNode(sections)
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCContactTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default])
		tableView.backgroundColor = UIColor.cellBackground
		tableView.separatorColor = UIColor.separator
		contacts = recent ?? []
	}
	
	private lazy var recent: [NCContact]? = {
		return NCCache.sharedCache?.viewContext.fetch("Contact", limit: 100, sortedBy: [NSSortDescriptor(key: "lastUse", ascending: false)], where: "lastUse <> nil")
	}()
	private lazy var gate = NCGate()

	
	func update(searchString: String) {
		let string = searchString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		
		let dataManager = self.dataManager
		
		gate.perform {
			guard string.count >= 3 else {
				DispatchQueue.main.async {
					self.contacts = self.recent ?? []
				}
				return
			}
			
			let result = try? dataManager.searchNames(string, categories: [.character, .corporation, .alliance], strict: false).get()
			DispatchQueue.main.async {
				let context = NCCache.sharedCache?.viewContext
				self.contacts = result?.values.compactMap {(try? context?.existingObject(with: $0)) as? NCContact}.sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
			}
		}
	}
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let node = node as? NCContactRow, let contact = node.contact else {return}
		delegate?.contactsSearchResultsViewController(self, didSelect: contact)
	}
}
