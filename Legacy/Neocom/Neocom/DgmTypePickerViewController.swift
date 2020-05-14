//
//  DgmTypePickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class DgmTypePickerViewController: NavigationController, View {
	
	typealias Presenter = DgmTypePickerPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	var input: Input? {
		didSet {
			guard oldValue?.category != input?.category else {return}
			if let input = input {
				viewControllers = try! [DgmTypePickerContainer.default.instantiate(input.category).get()]
			}
			else {
				viewControllers = []
			}
		}
	}
	
	struct Input {
		let category: SDEDgmppItemCategory
		let completion: (DgmTypePickerViewController, SDEInvType) -> Void
	}

	
	var unwinder: Unwinder?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
}
