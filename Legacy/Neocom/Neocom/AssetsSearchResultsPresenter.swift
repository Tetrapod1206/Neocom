//
//  AssetsSearchResultsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/8/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class AssetsSearchResultsPresenter: TreePresenter {
	typealias View = AssetsSearchResultsViewController
	typealias Interactor = AssetsSearchResultsInteractor
	typealias Presentation = [Tree.Item.Section<EVELocation, Tree.Item.AssetRow>]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.TreeDefaultCell.default])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {

		guard let string = searchManager.pop()?.lowercased(), !string.isEmpty else {return .init([])}
		let treeController = view?.treeController
		return DispatchQueue.global(qos: .utility).async {
			content.index.compactMap { i -> Tree.Item.Section<EVELocation, Tree.Item.AssetRow>? in
				let rows: Set<Tree.Item.AssetRow>
				if i.0.displayName.string.lowercased().contains(string) {
					rows = Set(i.1.values.joined())
				}
				else {
					rows = Set(i.1.filter {$0.key.contains(string)}.values.joined())
				}
				guard !rows.isEmpty else { return nil }
				let isExpanded = rows.count < 100
				return Tree.Item.Section(i.0,
										 isExpanded: isExpanded,
										 diffIdentifier: i.0,
										 treeController: treeController,
										 children: rows.sorted {$0.typeName < $1.typeName})
			}
		}
	}
	
	lazy var searchManager = SearchManager(presenter: self)
	
	func updateSearchResults(with string: String?) {
		searchManager.updateSearchResults(with: string ?? "")
		if let content = content, let prefix = string?.lowercased(), !prefix.isEmpty {
			let suggestions = content.suggestions.filter({$0.0.hasPrefix(prefix)}).prefix(3).map{$0.1}
			if !suggestions.isEmpty {
				view?.suggestions = suggestions
			}
			else {
				view?.suggestions = content.suggestions.filter({$0.0.contains(prefix)}).prefix(3).map{$0.1}
			}
		}
		else {
			view?.suggestions = nil
		}
	}
	
}
