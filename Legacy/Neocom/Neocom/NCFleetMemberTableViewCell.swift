//
//  NCFleetMemberTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

class NCFleetMemberTableViewCell: NCTableViewCell {
	@IBOutlet weak var characterNameLabel: UILabel!
	@IBOutlet weak var characterImageView: UIImageView!
	@IBOutlet weak var typeNameLabel: UILabel!
	@IBOutlet weak var shipNameLabel: UILabel!
	@IBOutlet weak var typeImageView: UIImageView!

}

extension Prototype {
	enum NCFleetMemberTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFleetMemberTableViewCell", bundle: nil), reuseIdentifier: "NCFleetMemberTableViewCell")
	}
}

class NCFleetMemberRow: TreeRow {
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.ship.typeID]
	}()
	
	
	let pilot: DGMCharacter
	let ship: DGMShip
	
	let shipName: String
	let characterName: String
	let level: Int?
	let characterID: Int64?
	var characterImage: UIImage?
	
	init(pilot: DGMCharacter, route: Route? = nil) {
		self.pilot = pilot
		self.ship = pilot.ship!
		self.shipName = ship.name
		
		let url = pilot.url ?? DGMCharacter.url(level: 0)
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		let query = components?.queryItems
		
		characterName = query?.first(where: {$0.name == "name"})?.value ?? " "
		
		if let value = query?.first(where: {$0.name == "level" })?.value  {
			level = Int(value)
		}
		else {
			level = nil
		}

		if let value = query?.first(where: {$0.name == "characterID" })?.value  {
			characterID = Int64(value)
		}
		else {
			characterID = nil
		}

		super.init(prototype: Prototype.NCFleetMemberTableViewCell.default, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFleetMemberTableViewCell else {return}
		guard let type = type else {return}
		
		cell.object = self
		cell.typeNameLabel?.text = type.typeName
		cell.shipNameLabel?.text = shipName
		cell.typeImageView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.characterNameLabel.text = characterName
		cell.characterImageView.image = characterImage
		if characterImage == nil {
			
			if let characterID = characterID {
				NCDataManager().image(characterID: characterID, dimension: Int(cell.characterImageView.bounds.size.width)).then(on: .main) { result in
					self.characterImage = result.value
					if (cell.object as? NCFleetMemberRow) == self {
						cell.characterImageView.image = self.characterImage
					}
				}
			}
			else {
				characterImage = UIImage.placeholder(text: String(romanNumber: level ?? 0), size: cell.characterImageView.bounds.size)
				cell.characterImageView.image = characterImage
			}

		}

	}
	
	override var hash: Int {
		return pilot.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFleetMemberRow)?.hash == hash
	}
	
}
