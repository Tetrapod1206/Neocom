//
//  NCFleetTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFleetTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var typeNamesStackView: UIStackView!
	@IBOutlet weak var shipNamesStackView: UIStackView!
	
}

extension Prototype {
	enum NCFleetTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFleetTableViewCell")
	}
}


class NCFleetRow: NCFetchedResultsObjectNode<NCFleet>, TreeNodeRoutable {
	
	var route: Route?
	var accessoryButtonRoute: Route?
	
	required init(object: NCFleet) {
		super.init(object: object)
//		cellIdentifier = Prototype.NCFleetTableViewCell.default.reuseIdentifier
		cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
		route = Router.Fitting.Editor(fleetID: object.objectID)
	}
	
	var loadouts: [String] {
		var loadouts = [String]()

		let invTypes = NCDatabase.sharedDatabase?.invTypes
		
		for loadout in self.object.loadouts?.array as? [NCLoadout] ?? [] {
			let type = invTypes?[Int(loadout.typeID)]
			loadouts.append(type?.typeName ?? NSLocalizedString("Unknown", comment: ""))
		}
		
		return loadouts
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.name
		let loadouts = self.loadouts
		cell.subtitleLabel?.text = loadouts.isEmpty ? NSLocalizedString("Empty", comment: "") : loadouts.map {$0}.joined(separator: ",")
		cell.accessoryType = .disclosureIndicator
		
		/*guard let cell = cell as? NCFleetTableViewCell else {return}
		
		cell.titleLabel.text = object.name
		
		if cell.typeNamesStackView.arrangedSubviews.count > loadouts.count {
			for _ in loadouts.count..<cell.typeNamesStackView.arrangedSubviews.count {
				cell.typeNamesStackView.removeArrangedSubview(cell.typeNamesStackView.arrangedSubviews.last!)
				cell.shipNamesStackView.removeArrangedSubview(cell.shipNamesStackView.arrangedSubviews.last!)
			}
		}
		else if cell.typeNamesStackView.arrangedSubviews.count < loadouts.count {
			let typeNamePrototype = cell.typeNamesStackView.arrangedSubviews.first as? UILabel
			let shipNamePrototype = cell.shipNamesStackView.arrangedSubviews.first as? UILabel

			for _ in cell.typeNamesStackView.arrangedSubviews.count..<loadouts.count {
				let typeNameLabel = UILabel()
				typeNameLabel.font = typeNamePrototype?.font ?? UIFont.preferredFont(forTextStyle: .footnote)
				typeNameLabel.textColor = typeNamePrototype?.textColor ?? UIColor.caption
				
				let shipNameLabel = UILabel()
				shipNameLabel.font = shipNamePrototype?.font ?? UIFont.preferredFont(forTextStyle: .footnote)
				shipNameLabel.textColor = shipNamePrototype?.textColor ?? UIColor.lightText

				cell.typeNamesStackView.addArrangedSubview(typeNameLabel)
				cell.shipNamesStackView.addArrangedSubview(shipNameLabel)
			}
		}
		
		for (i, (name, typeName, image)) in loadouts.enumerated() {
			(cell.shipNamesStackView.arrangedSubviews[i] as! UILabel).text = name
			let typeNameLabel = cell.typeNamesStackView.arrangedSubviews[i] as! UILabel
			typeNameLabel.attributedText = NSAttributedString(image: image ?? NCDBEveIcon.defaultType.image?.image, font: typeNameLabel.font) + " " + (typeName ?? "")
		}*/
	}
	
}
