//
//  NCFittingSlotHeaderTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingSlotHeaderTableViewCell: NCHeaderTableViewCell {
	@IBOutlet weak var groupButton: UIButton?
	
}

extension Prototype {
	enum NCFittingSlotHeaderTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFittingSlotHeaderTableViewCell")
	}
}
