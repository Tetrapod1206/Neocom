//
//  Cells.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class RowCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		selectedBackgroundView = UIView(frame: bounds)
		selectedBackgroundView?.backgroundColor = .separator
		tintColor = .caption
	}
	
	override var indentationLevel: Int {
		didSet {
			layoutMargins.left = layoutMargins.right + indentationWidth * max(CGFloat(indentationLevel - 1), 0)
		}
	}
}

class HeaderCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		selectedBackgroundView = UIView(frame: bounds)
		selectedBackgroundView?.backgroundColor = .cellBackground
		tintColor = .caption
	}
	
}
