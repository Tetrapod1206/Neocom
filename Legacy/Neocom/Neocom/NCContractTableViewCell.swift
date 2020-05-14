//
//  NCContractTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCContractTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
}

extension Prototype {
	enum NCContractTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCContractTableViewCell")
	}
}

class NCContractRow: TreeRow {
	let contract: ESI.Contracts.Contract
	let contacts: [Int64: NSManagedObjectID]?
	let location: NCLocation?
	let endDate: Date
	let characterID: Int64
	
	lazy var issuer: NCContact? = {
		guard let objectID = contacts?[Int64(contract.issuerID)] else {return nil}
		return (try? NCCache.sharedCache?.viewContext.existingObject(with: objectID)) as? NCContact
	}()
	
	init(contract: ESI.Contracts.Contract, characterID: Int64, contacts: [Int64: NSManagedObjectID]?, location: NCLocation?) {
		self.contract = contract
		self.characterID = characterID
		self.contacts = contacts
		self.location = location
		endDate = contract.dateCompleted ?? {
			guard let date = contract.dateAccepted, let duration = contract.daysToComplete else {return nil}
			return date.addingTimeInterval(TimeInterval(duration) * 24 * 3600)
		}() ?? contract.dateExpired
		
		super.init(prototype: Prototype.NCContractTableViewCell.default, route: Router.Contract.Info(contract: contract))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCContractTableViewCell else {return}

		let type = contract.type.title
		
		let availability = contract.availability.title
		
		let t = contract.dateExpired.timeIntervalSinceNow
		
		let status = contract.currentStatus
		
		let color = status == .outstanding || status == .inProgress ? UIColor.white : UIColor.lightText
		
		if status == .outstanding || status == .inProgress {
			cell.titleLabel.attributedText = type * [NSAttributedStringKey.foregroundColor: color] + " [\(availability)]" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
		}
		else {
			cell.titleLabel.attributedText = "\(type) [\(availability)]" * [NSAttributedStringKey.foregroundColor: color]
		}
		
		cell.subtitleLabel.text = contract.title
		cell.locationLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown", comment: "") * [:]
		
		switch status {
		case .outstanding, .inProgress:
			cell.stateLabel.attributedText = status.title * [NSAttributedStringKey.foregroundColor: color] + " " + NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes) * [NSAttributedStringKey.foregroundColor: UIColor.lightText]
		default:
			cell.stateLabel.attributedText = "\(status.title) \(DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .medium))" * [NSAttributedStringKey.foregroundColor: UIColor.lightText]
		}
		
		if contract.issuerID == Int(characterID) {
			cell.dateLabel.text = DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)
		}
		else if let issuer = issuer?.name {
			cell.dateLabel.text = "\(DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)) \(NSLocalizedString("by", comment: "")) \(issuer)"
		}
	}
	
	override var hash: Int {
		return contract.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContractRow)?.hashValue == hashValue
	}
}

