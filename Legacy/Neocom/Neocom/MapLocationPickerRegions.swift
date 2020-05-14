//
//  MapLocationPickerRegions.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MapLocationPickerRegions: Assembly {
	typealias View = MapLocationPickerRegionsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "MapLocationPickerRegionsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}
