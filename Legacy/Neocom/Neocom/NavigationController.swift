//
//  NavigationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class NavigationController: UINavigationController {
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationBar.isTranslucent = false
	}
}
