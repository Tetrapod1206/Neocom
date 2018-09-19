//
//  TreeDefaultCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class TreeDefaultCell: RowCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var subtitleLabel: UILabel?
	@IBOutlet var iconView: UIImageView?
}

extension Prototype {
	enum TreeDefaultCell {
		static let `default` = Prototype(nib: UINib(nibName: "TreeDefaultCell", bundle: nil), reuseIdentifier: "TreeDefaultCell")
	}
}

extension Tree.Content {
	struct Default: Hashable {
		var prototype: Prototype?
		var title: String?
		var subtitle: String?
		var attributedTitle: NSAttributedString?
		var attributedSubtitle: NSAttributedString?
		var image: UIImage?
		
		init(prototype: Prototype = Prototype.TreeDefaultCell.default,
			 title: String? = nil,
			 subtitle: String? = nil,
			 attributedTitle: NSAttributedString? = nil,
			 attributedSubtitle: NSAttributedString? = nil,
			 image: UIImage? = nil) {
			self.prototype = prototype
			self.title = title
			self.subtitle = subtitle
			self.attributedTitle = attributedTitle
			self.attributedSubtitle = attributedSubtitle
			self.image = image
		}
	}
}

extension Tree.Content.Default: CellConfiguring {
	
	func configure(cell: UITableViewCell) {
		guard let cell = cell as? TreeDefaultCell else {return}
		if let attributedTitle = attributedTitle {
			cell.titleLabel?.attributedText = attributedTitle
			cell.titleLabel?.isHidden = false
		}
		else if let title = title {
			cell.titleLabel?.text = title
			cell.titleLabel?.isHidden = false
		}
		else {
			cell.titleLabel?.text = nil
			cell.titleLabel?.isHidden = true
		}
		
		if let attributedSubtitle = attributedSubtitle {
			cell.subtitleLabel?.attributedText = attributedSubtitle
			cell.subtitleLabel?.isHidden = false
		}
		else if let subtitle = subtitle {
			cell.subtitleLabel?.text = subtitle
			cell.subtitleLabel?.isHidden = false
		}
		else {
			cell.subtitleLabel?.text = nil
			cell.subtitleLabel?.isHidden = true
		}
		
		if let image = image {
			cell.iconView?.image = image
			cell.iconView?.isHidden = false
		}
		else {
			cell.iconView?.image = nil
			cell.iconView?.isHidden = true
		}
	}
}
