//
//  InvTypeInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible
import CoreData
import Dgmpp

class InvTypeInfoPresenter: TreePresenter {
	typealias View = InvTypeInfoViewController
	typealias Interactor = InvTypeInfoInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	private var invType: SDEInvType?
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								 Prototype.TreeDefaultCell.attribute,
								 Prototype.DamageTypeCell.compact,
								 Prototype.TreeDefaultCell.default,
								 Prototype.InvTypeInfoDescriptionCell.default,
								 Prototype.InvTypeInfoDescriptionCell.compact,
								 Prototype.MarketHistoryCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
		
		switch view?.input {
		case let .objectID(objectID)?:
			invType = (try? Services.sde.viewContext.existingObject(with: objectID)) ?? nil
		case let .type(type)?:
			invType = type
		case let .typeID(typeID)?:
			invType = Services.sde.viewContext.invType(typeID)
		default:
			break
		}
		
		view?.title = invType?.typeName ?? NSLocalizedString("Type Info", comment: "")
		
		if let typeID = invType?.typeID {
			if Services.storage.viewContext.marketQuickItem(with: Int(typeID)) != nil {
				view?.setRightBarButtonItemImage(#imageLiteral(resourceName: "favoritesOn"))
			}
			else if invType?.marketGroup != nil {
				view?.setRightBarButtonItemImage(#imageLiteral(resourceName: "favoritesOff"))
			}
		}
		
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let objectID = invType?.objectID else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let progress = Progress(totalUnitCount: 2)
		
		return Services.sde.performBackgroundTask { (context) -> Presentation in
			let type: SDEInvType = try context.existingObject(with: objectID)
			let categoryID = (type.group?.category?.categoryID).flatMap { SDECategoryID(rawValue: $0)}
			
			var presentation: [AnyTreeItem] = progress.performAsCurrent(withPendingUnitCount: 1) {
				switch categoryID {
				case .blueprint?:
					return self.blueprintInfoPresentation(for: type, character: content.value, context: context)
				case .entity?:
					return self.npcInfoPresentation(for: type, character: content.value, context: context)
				default:
					if type.wormhole != nil {
						return self.whInfoPresentation(for: type, character: content.value, context: context)

					}
					else {
						return self.typeInfoPresentation(for: type, character: content.value, context: context, attributeValues: nil)
					}
				}
			}
			
			if type.marketGroup != nil {
				let marketSection = Tree.Item.Section<Tree.Content.Section, AnyTreeItem>(Tree.Content.Section(title: NSLocalizedString("Market", comment: "").uppercased()), diffIdentifier: "MarketSection", expandIdentifier: "MarketSection", treeController: self.view?.treeController, children: [])
				
				presentation.insert(marketSection.asAnyItem, at: 0)
				
				let marketRoute = Router.SDE.invTypeMarketOrders(.typeID(Int(type.typeID)))
				
				self.interactor.price(typeID: Int(type.typeID)).then(on: .main) { result in
					let subtitle = UnitFormatter.localizedString(from: result, unit: .isk, style: .long)
					let price = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		   title: NSLocalizedString("PRICE", comment: ""),
																		   subtitle: subtitle,
																		   image: Image( #imageLiteral(resourceName: "wallet")),
																		   accessoryType: .disclosureIndicator),
													  diffIdentifier: "Price",
													  route: marketRoute )
					marketSection.children?.insert(price.asAnyItem, at: 0)
					self.view?.treeController.update(contentsOf: marketSection)
				}
				
				self.interactor.marketHistory(typeID: Int(type.typeID)).then(on: .global(qos: .utility)) { result in
					return Tree.Item.RoutableRow(Tree.Content.MarketHistory(history: result), diffIdentifier: "MarketHistory", route: marketRoute)
				}.then(on: .main) { history in
					marketSection.children?.append(history.asAnyItem)
					self.view?.treeController.update(contentsOf: marketSection)
				}
			}
			
			let image = type.icon?.image?.image ?? context.eveIcon(.defaultType)?.image?.image
			
			let subtitle = type.marketGroup.map { sequence(first: $0, next: {$0.parentGroup})}?.compactMap { $0.marketGroupName }.joined(separator: " / ")
			
			var description = Tree.Content.InvTypeInfoDescription(prototype: Prototype.InvTypeInfoDescriptionCell.compact, title: type.typeName ?? "", subtitle: subtitle, image: image, typeDescription: type.typeDescription?.text)
			let descriptionRow = Tree.Item.Row<Tree.Content.InvTypeInfoDescription>(description, diffIdentifier: "Description")
			
			presentation.insert(descriptionRow.asAnyItem, at: 0)
			
			self.interactor.fullSizeImage(typeID: Int(type.typeID), dimension: 512).then(on: .main) { result in
				description.image = result
				description.prototype = Prototype.InvTypeInfoDescriptionCell.default
				presentation[0] = Tree.Item.Row<Tree.Content.InvTypeInfoDescription>(description, diffIdentifier: "Description").asAnyItem
				self.view?.treeController.reloadRow(for: presentation[0], with: .fade)
			}
			
			return presentation
		}
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let character = content?.value else {return}
		guard let item = item as? Tree.Item.InvTypeRequiredSkillRow else {return}
		guard let type = Services.sde.viewContext.invType(item.skill.skill.typeID) else {return}
		let trainingQueue = TrainingQueue(character: character)
		trainingQueue.add(type, level: item.level)
		guard trainingQueue.queue.count > 0 else {return}
		
		onAddToSkillPlan(trainingQueue: trainingQueue, sender: view?.treeController.cell(for: item))
	}

	func onAddToSkillPlan(trainingQueue: TrainingQueue, sender: Any?) {
		
		guard let account = Services.storage.viewContext.currentAccount, let skillPlan = account.activeSkillPlan else {return}
		
		let trainingTime = trainingQueue.trainingTime()
		guard trainingTime > 0 else {return}
		
		let controller = UIAlertController(add: trainingQueue, to: skillPlan) { [weak self] _ in
			skillPlan.add(trainingQueue)
			try? Services.storage.viewContext.save()
			self?.view?.tableView.reloadData()
		}
		
		view?.present(controller, animated: true)
	}
	
	func onFavorites() {
		if let typeID = invType?.typeID {
			if let marketQuickItem = Services.storage.viewContext.marketQuickItem(with: Int(typeID)) {
				marketQuickItem.managedObjectContext?.delete(marketQuickItem)
				view?.setRightBarButtonItemImage(#imageLiteral(resourceName: "favoritesOff"))
			}
			else if invType?.marketGroup != nil {
				view?.setRightBarButtonItemImage(#imageLiteral(resourceName: "favoritesOn"))
				let marketQuickItem = MarketQuickItem(context: Services.storage.viewContext.managedObjectContext)
				marketQuickItem.typeID = typeID
			}
			try? Services.storage.viewContext.save()
		}
	}
}

extension Tree.Item {
	
	class DgmAttributeRow: RoutableRow<Tree.Content.Default> {
		
		init(attribute: SDEDgmTypeAttribute, value: Double?, context: SDEContext) {
			func toString(_ value: Double) -> String {
				var s = UnitFormatter.localizedString(from: value, unit: .none, style: .long)
				if let unit = attribute.attributeType?.unit?.displayName {
					s += " " + unit
				}
				return s
			}
			
			let unitID = (attribute.attributeType?.unit?.unitID).flatMap {SDEUnitID(rawValue: $0)} ?? .none
			let value = value ?? attribute.value
			
			var route: Routing?
			var icon: SDEEveIcon?
			var subtitle: String?
			
			switch unitID {
			case .attributeID:
				let attributeType = context.dgmAttributeType(Int(value))
				subtitle = attributeType?.displayName ?? attributeType?.attributeName
			case .groupID:
				let group = context.invGroup(Int(value))
				subtitle = group?.groupName
				icon = attribute.attributeType?.icon ?? group?.icon
				route = group.map{Router.SDE.invTypes(.group($0))}
			case .typeID:
				let type = context.invType(Int(value))
				subtitle = type?.typeName
				icon = type?.icon ?? attribute.attributeType?.icon
				route = Router.SDE.invTypeInfo(.typeID(Int(value)))
			case .sizeClass:
				subtitle = SDERigSize(rawValue: Int(value))?.description ?? String(describing: Int(value))
			case .bonus:
				subtitle = "+" + UnitFormatter.localizedString(from: value, unit: .none, style: .long)
				icon = attribute.attributeType?.icon
			case .boolean:
				subtitle = Int(value) == 0 ? NSLocalizedString("No", comment: "") : NSLocalizedString("Yes", comment: "")
			case .inverseAbsolutePercent, .inversedModifierPercent:
				subtitle = toString((1.0 - value) * 100.0)
			case .modifierPercent:
				subtitle = toString((value - 1.0) * 100.0)
			case .absolutePercent:
				subtitle = toString(value * 100.0)
			case .milliseconds:
				subtitle = toString(value / 1000.0)
			default:
				subtitle = toString(value)
			}
			
			let title: String
			if let displayName = attribute.attributeType?.displayName, !displayName.isEmpty {
				title = displayName
			}
			else if let attributeName = attribute.attributeType?.attributeName, !attributeName.isEmpty {
				title = attributeName
			}
			else {
				title = "\(attribute.attributeType?.attributeID ?? 0)"
			}
			
			let content = Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute, title: title.uppercased(), subtitle: subtitle, image: Image(icon ?? attribute.attributeType?.icon), accessoryType: route == nil ? .none : .disclosureIndicator)
			
			super.init(content, diffIdentifier: attribute.objectID, route: route)
		}
	}
	
	class InvTypeRequiredSkillRow: TreeItem, CellConfigurable, Routable {
		var prototype: Prototype? { return Prototype.TreeDefaultCell.default}
		let skill: TrainingQueue.Item
		let level: Int
		let image: UIImage?
		let title: NSAttributedString
		let subtitle: String?
		let tintColor: UIColor
		let trainingTime: TimeInterval
		let route: Routing?
		let accessoryType: UITableViewCell.AccessoryType
		
		init?(type: SDEInvType, level: Int, character: Character?, route: Routing?, accessoryType: UITableViewCell.AccessoryType) {
			guard let skill = Character.Skill(type: type) else {return nil}
			title = NSAttributedString(skillName: type.typeName ?? "", level: level)
			self.level = level

			
			let trainedSkill = character?.trainedSkills[Int(type.typeID)]
			
			let item = TrainingQueue.Item(skill: skill, targetLevel: level, startSP: Int(trainedSkill?.skillpointsInSkill ?? 0))
			self.skill = item
			
			if let character = character {
				if let trainedSkill = trainedSkill, trainedSkill.trainedSkillLevel >= level {
					image = #imageLiteral(resourceName: "skillRequirementMe")
					subtitle = nil
					tintColor = .white
					trainingTime = 0
				}
				else {
					image = #imageLiteral(resourceName: "skillRequirementNotMe")
					let trainingTime = item.trainingTime(with: character.attributes)
					subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
					tintColor = trainingTime > 0 ? .lightText : .white
					self.trainingTime = trainingTime
				}
			}
			else {
				image = #imageLiteral(resourceName: "skillRequirementNotInjected")
				subtitle = nil
				tintColor = .white
				trainingTime = 0
			}
			self.route = route
			self.accessoryType = accessoryType
//			route = Router.SDE.invTypeInfo(.objectID(type.objectID))
		}
		
		convenience init?(_ skill: SDEInvTypeRequiredSkill, character: Character?) {
			guard let type = skill.skillType else {return nil}
			self.init(type: type, level: Int(skill.skillLevel), character: character, route: Router.SDE.invTypeInfo(.objectID(type.objectID)), accessoryType: .disclosureIndicator)
		}
		
		convenience init?(_ skill: SDEIndRequiredSkill, character: Character?) {
			guard let type = skill.skillType else {return nil}
			self.init(type: type, level: Int(skill.skillLevel), character: character, route: Router.SDE.invTypeInfo(.objectID(type.objectID)), accessoryType: .disclosureIndicator)
		}
		
		convenience init?(_ skill: SDECertSkill, character: Character?) {
			guard let type = skill.type else {return nil}
			self.init(type: type, level: Int(skill.skillLevel), character: character, route: Router.SDE.invTypeInfo(.objectID(type.objectID)), accessoryType: .disclosureIndicator)
		}

		static func == (lhs: Tree.Item.InvTypeRequiredSkillRow, rhs: Tree.Item.InvTypeRequiredSkillRow) -> Bool {
			return lhs === rhs
		}

		func configure(cell: UITableViewCell, treeController: TreeController?) {
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.isHidden = false
			cell.subtitleLabel?.isHidden = false
			
			cell.titleLabel?.attributedText = title
			cell.subtitleLabel?.text = subtitle
			cell.iconView?.image = image
			cell.iconView?.tintColor = tintColor
			
			let typeID = skill.skill.typeID
			let item = Services.storage.viewContext.currentAccount?.activeSkillPlan?.skills?.first(where: { (skill) -> Bool in
				let skill = skill as! SkillPlanSkill
				return Int(skill.typeID) == typeID && Int(skill.level) >= level
			})
			if item != nil {
				cell.iconView?.image = #imageLiteral(resourceName: "skillRequirementQueued")
				cell.iconView?.isHidden = false
			}
			else {
				cell.iconView?.image = nil
				cell.iconView?.isHidden = true
			}
			cell.accessoryType = accessoryType
		}
		
		var hashValue: Int {
			return skill.hashValue
		}
		
		var children: [InvTypeRequiredSkillRow]?
	}
	
	class InvTypeSkillsSection: Section<Tree.Content.Section, Tree.Item.InvTypeRequiredSkillRow> {
		init<T: Hashable>(title: String, trainingQueue: TrainingQueue, character: Character?, diffIdentifier: T, expandIdentifier: CustomStringConvertible? = nil, treeController: TreeController?, isExpanded: Bool = true, children: [Tree.Item.InvTypeRequiredSkillRow]?, action: ((UIControl) -> Void)?) {
			let trainingTime = trainingQueue.trainingTime()
			
			let attributedTitle: NSAttributedString
			if trainingTime > 0 {
				attributedTitle = title + " " + TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) * [NSAttributedString.Key.foregroundColor: UIColor.white]
			}
			else {
				attributedTitle = NSAttributedString(string: title)
			}
			
//			let actions: Tree.Content.Section.Actions = character == nil || trainingTime == 0 ? [] : [.normal]
			let content = Tree.Content.Section(attributedTitle: attributedTitle)
			//TODO: Add SkillQueue handler
			super.init(content, isExpanded: isExpanded, diffIdentifier: diffIdentifier, expandIdentifier: expandIdentifier, treeController: treeController, children: children, action: action)
		}
		
	}
}

extension InvTypeInfoPresenter {
	
	func typeInfoPresentation(for type: SDEInvType, character: Character?, context: SDEContext, attributeValues: [Int: Double]?) -> [AnyTreeItem] {
		var sections = [AnyTreeItem]()
		
		if let section = skillPlanPresentation(for: type, character: character, context: context) {
			sections.append(section.asAnyItem)
		}

		if let section = masteriesPresentation(for: type, character: character, context: context) {
			sections.append(section.asAnyItem)
		}
		
		if let section = variationsPresentation(for: type, context: context) {
			sections.append(section.asAnyItem)
		}

		if let section = requiredForPresentation(for: type, context: context) {
			sections.append(section.asAnyItem)
		}

		let results = context.managedObjectContext.from(SDEDgmTypeAttribute.self)
			.filter(\SDEDgmTypeAttribute.type == type && \SDEDgmTypeAttribute.attributeType?.published == true)
			.sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
			.sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
			.fetchedResultsController(sectionName: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
		
		do {
			try results.performFetch()
			sections.append(contentsOf:
				results.sections?.compactMap { section -> AnyTreeItem? in
					guard let attributeCategory = (section.objects?.first as? SDEDgmTypeAttribute)?.attributeType?.attributeCategory else {return nil}
					
					if SDEAttributeCategoryID(rawValue: attributeCategory.categoryID) == .requiredSkills {
						guard let section = requiredSkillsPresentation(for: type, character: character, context: context) else {return nil}
						return section.asAnyItem
					}
					else {
						let sectionTitle: String = SDEAttributeCategoryID(rawValue: attributeCategory.categoryID) == .null ? NSLocalizedString("Other", comment: "") : attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
						
						var rows = [AnyTreeItem]()
						
						var damageRow: Tree.Item.DamageTypeRow?
						func damage() -> Tree.Item.DamageTypeRow? {
							if damageRow == nil {
								damageRow = Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact, unit: .none, em: 0, thermal: 0, kinetic: 0, explosive: 0))
							}
							return damageRow
						}
						
						var resistanceRow: Tree.Item.DamageTypeRow?
						func resistance() -> Tree.Item.DamageTypeRow? {
							if resistanceRow == nil {
								resistanceRow = Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact, unit: .percent, em: 0, thermal: 0, kinetic: 0, explosive: 0))
							}
							return resistanceRow
						}
						
						(section.objects as? [SDEDgmTypeAttribute])?.forEach { attribute in
							let value = attributeValues?[Int(attribute.attributeType!.attributeID)] ?? attribute.value
							
							switch SDEAttributeID(rawValue: attribute.attributeType!.attributeID) {
							case .emDamageResonance?, .armorEmDamageResonance?, .shieldEmDamageResonance?,
								 .hullEmDamageResonance?, .passiveArmorEmDamageResonance?, .passiveShieldEmDamageResonance?:
								guard let row = resistance() else {return}
								row.content.em = max(row.content.em, 1 - value)
							case .thermalDamageResonance?, .armorThermalDamageResonance?, .shieldThermalDamageResonance?,
								 .hullThermalDamageResonance?, .passiveArmorThermalDamageResonance?, .passiveShieldThermalDamageResonance?:
								guard let row = resistance() else {return}
								row.content.thermal = max(row.content.thermal, 1 - value)
							case .kineticDamageResonance?, .armorKineticDamageResonance?, .shieldKineticDamageResonance?,
								 .hullKineticDamageResonance?, .passiveArmorKineticDamageResonance?, .passiveShieldKineticDamageResonance?:
								guard let row = resistance() else {return}
								row.content.kinetic = max(row.content.kinetic, 1 - value)
							case .explosiveDamageResonance?, .armorExplosiveDamageResonance?, .shieldExplosiveDamageResonance?,
								 .hullExplosiveDamageResonance?, .passiveArmorExplosiveDamageResonance?, .passiveShieldExplosiveDamageResonance?:
								guard let row = resistance() else {return}
								row.content.explosive = max(row.content.explosive, 1 - value)
							case .emDamage?:
								damage()?.content.em = value
							case .thermalDamage?:
								damage()?.content.thermal = value
							case .kineticDamage?:
								damage()?.content.kinetic = value
							case .explosiveDamage?:
								damage()?.content.explosive = value
								
							case .warpSpeedMultiplier?:
								guard let attributeType = attribute.attributeType else {return}
								
								let baseWarpSpeed =  attributeValues?[Int(SDEAttributeID.baseWarpSpeed.rawValue)] ?? type[SDEAttributeID.baseWarpSpeed]?.value ?? 1.0
								var s = UnitFormatter.localizedString(from: Double(value * baseWarpSpeed), unit: .none, style: .long)
								s += " " + NSLocalizedString("AU/sec", comment: "")
								let row = Tree.Item.Row<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute, title: NSLocalizedString("Warp Speed", comment: "").uppercased(), subtitle: s, image: Image(attributeType.icon)), diffIdentifier: "WarpSpeed")
								rows.append(row.asAnyItem)
							default:
								let row = Tree.Item.DgmAttributeRow(attribute: attribute, value: value, context: context)
								rows.append(row.asAnyItem)
							}
						}
						
						if let resistanceRow = resistanceRow {
							rows.append(resistanceRow.asAnyItem)
							
						}
						if let damageRow = damageRow {
							rows.append(damageRow.asAnyItem)
						}
						guard !rows.isEmpty else {return nil}
						
						return Tree.Item.Section(Tree.Content.Section(title: sectionTitle.uppercased()),
												 diffIdentifier: attributeCategory.objectID,
												 expandIdentifier: attributeCategory.objectID,
												 treeController: view?.treeController,
												 children: rows).asAnyItem
						
					}
				} ?? [])
		}
		catch {
		}
		
		
		return sections
	}
	
	func variationsPresentation(for type: SDEInvType, context: SDEContext) -> Tree.Item.Section<Tree.Content.Section, Tree.Item.RoutableRow<Tree.Content.Default>>? {
		guard type.parentType != nil || (type.variations?.count ?? 0) > 0 else {return nil}
		let n = max(type.variations?.count ?? 0, type.parentType?.variations?.count ?? 0) + 1
		let row = Tree.Item.RoutableRow<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute, title: String.localizedStringWithFormat("%d types", n).uppercased(), accessoryType: .disclosureIndicator),
															  diffIdentifier: "Variations",
															  route: Router.SDE.invTypeVariations(.objectID(type.objectID)))
		let section = Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Variations", comment: "").uppercased()), diffIdentifier: "VariationsSection", expandIdentifier: "VariationsSection", treeController: view?.treeController, children: [row])
		return section
	}
	
	func requiredForPresentation(for type: SDEInvType, context: SDEContext) -> Tree.Item.Section<Tree.Content.Section, Tree.Item.RoutableRow<Tree.Content.Default>>? {
		guard let n = type.requiredForSkill?.count, n > 0 else { return nil }
		let row = Tree.Item.RoutableRow<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		   title: String.localizedStringWithFormat("%d types", n).uppercased()),
															  diffIdentifier: "RequiredFor",
															  route: Router.SDE.invTypeRequiredFor(.objectID(type.objectID)))
		let section = Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Required for", comment: "").uppercased()), diffIdentifier: "RequiredForSection", expandIdentifier: "RequiredForSection", treeController: view?.treeController, children: [row])
		return section
	}
	
	func skillPlanPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.Section<Tree.Content.Section, Tree.Item.InvTypeRequiredSkillRow>? {
		guard (type.group?.category?.categoryID).flatMap({SDECategoryID(rawValue: $0)}) == .skill else {return nil}
		

		let rows = (1...5).compactMap { Tree.Item.InvTypeRequiredSkillRow(type: type, level: $0, character: character, route: nil, accessoryType: .none) }
			.filter {$0.trainingTime > 0}
		guard !rows.isEmpty else {return nil}
		
		return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Skill Plan", comment: "").uppercased()), diffIdentifier: "SkillPlan", expandIdentifier: "SkillPlan", treeController: view?.treeController, children: rows)
	}
	
	func masteriesPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.Section<Tree.Content.Section, Tree.Item.Row<Tree.Content.Default>>? {
		var masteries = [Int: [SDECertMastery]]()
		
		(type.certificates?.allObjects as? [SDECertCertificate])?.forEach { certificate in
			(certificate.masteries?.array as? [SDECertMastery])?.forEach { mastery in
				masteries[Int(mastery.level?.level ?? 0), default: []].append(mastery)
			}
		}
		
		let unclaimedIcon = context.eveIcon(.mastery(nil))
		
		let character = character ?? .empty
		
		let rows = masteries.sorted {$0.key < $1.key}.compactMap { (key, array) -> Tree.Item.Row<Tree.Content.Default>? in
			guard let mastery = array.first else {return nil}
			guard let level = mastery.level else {return nil}
			
			let trainingQueue = TrainingQueue(character: character)
			array.forEach {trainingQueue.add($0)}
			let trainingTime = trainingQueue.trainingTime(with: character.attributes)
			
			let title = NSLocalizedString("Level", comment: "").uppercased() + " \(String(romanNumber: key + 1))"
			let subtitle = trainingTime > 0 ? TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds) : nil
			let icon = trainingTime > 0 ? unclaimedIcon : level.icon
			
			let route = Router.SDE.invTypeMastery(InvTypeMastery.View.Input(typeObjectID: type.objectID, masteryLevelObjectID: level.objectID))
			
			return Tree.Item.RoutableRow<Tree.Content.Default>(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute, title: title, subtitle: subtitle, image: Image(icon)), diffIdentifier: level.objectID, route: route)
		}
		
		guard !rows.isEmpty else {return nil}
		return Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("Mastery", comment: "").uppercased()), diffIdentifier: "Mastery", expandIdentifier: "Mastery", treeController: view?.treeController, children: rows)
	}
	
	func requiredSkillsPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> Tree.Item.InvTypeSkillsSection? {
		guard let rows = requiredSkills(for: type, character: character, context: context), !rows.isEmpty else {return nil}
		let trainingQueue = TrainingQueue(character: character ?? .empty)
		trainingQueue.addRequiredSkills(for: type)
		
		let action: ((UIControl) -> Void)? = character == nil || trainingQueue.queue.isEmpty ? nil : { [weak self] sender in
			self?.onAddToSkillPlan(trainingQueue: trainingQueue, sender: sender)
		}
		
		return Tree.Item.InvTypeSkillsSection(title: NSLocalizedString("Required Skills", comment: "").uppercased(),
									   trainingQueue: trainingQueue,
									   character: character,
									   diffIdentifier: "RequiredSkills",
									   expandIdentifier: "RequiredSkills",
									   treeController: view?.treeController,
									   children: rows,
									   action: action)
	}
	
	private func requiredSkills(for type: SDEInvType, character: Character?, context: SDEContext) -> [Tree.Item.InvTypeRequiredSkillRow]? {
		return (type.requiredSkills?.array as? [SDEInvTypeRequiredSkill])?.compactMap { requiredSkill -> Tree.Item.InvTypeRequiredSkillRow? in
			guard let type = requiredSkill.skillType else {return nil}
			guard let row = Tree.Item.InvTypeRequiredSkillRow(requiredSkill, character: character) else {return nil}
			row.children = requiredSkills(for: type, character: character, context: context)
			return row
		}
	}

	func requiredSkillsPresentation(for activity: SDEIndActivity, character: Character?, context: SDEContext) -> Tree.Item.InvTypeSkillsSection? {
		guard let rows = requiredSkills(for: activity, character: character, context: context), !rows.isEmpty else {return nil}
		let trainingQueue = TrainingQueue(character: character ?? .empty)
		trainingQueue.addRequiredSkills(for: activity)
		
		let action: ((UIControl) -> Void)? = character == nil || trainingQueue.queue.isEmpty ? nil : { [weak self] sender in
			self?.onAddToSkillPlan(trainingQueue: trainingQueue, sender: sender)
		}

		return Tree.Item.InvTypeSkillsSection(title: NSLocalizedString("Required Skills", comment: "").uppercased(),
											  trainingQueue: trainingQueue,
											  character: character,
											  diffIdentifier: "\(activity.objectID).requiredSkills",
											  expandIdentifier: "\(activity.objectID).requiredSkills",
											  treeController: view?.treeController,
											  children: rows,
											  action: action)
	}

	
	private func requiredSkills(for activity: SDEIndActivity, character: Character?, context: SDEContext) -> [Tree.Item.InvTypeRequiredSkillRow]? {
		return (activity.requiredSkills?.allObjects as? [SDEIndRequiredSkill])?.filter {$0.skillType?.typeName != nil}.sorted {$0.skillType!.typeName! < $1.skillType!.typeName!}.compactMap { requiredSkill -> Tree.Item.InvTypeRequiredSkillRow? in
			guard let type = requiredSkill.skillType else {return nil}
			guard let row = Tree.Item.InvTypeRequiredSkillRow(requiredSkill, character: character) else {return nil}
			row.children = requiredSkills(for: type, character: character, context: context)
			return row
		}
	}

	func blueprintInfoPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> [AnyTreeItem] {
		
		let activities = (type.blueprintType?.activities?.allObjects as? [SDEIndActivity])?.sorted {$0.activity!.activityID < $1.activity!.activityID}

		return activities?.map { activity -> AnyTreeItem in
			var rows = [AnyTreeItem]()
			let time = TimeIntervalFormatter.localizedString(from: TimeInterval(activity.time), precision: .seconds)
			let row = Tree.Item.Row(Tree.Content.Default(subtitle: time, image: Image( #imageLiteral(resourceName: "skillRequirementQueued"))), diffIdentifier: "\(activity.activity!.activityID).time")
			rows.append(row.asAnyItem)
			
			let products = (activity.products?.allObjects as? [SDEIndProduct])?.filter {$0.productType?.typeName != nil}.sorted {$0.productType!.typeName! < $1.productType!.typeName!}.map { product -> AnyTreeItem in
				let title = NSLocalizedString("PRODUCT", comment: "")
				let image = Image(product.productType?.icon)
				let row = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute, title: title, subtitle: product.productType!.typeName!, image: image, accessoryType: .disclosureIndicator), diffIdentifier: product.objectID, route: Router.SDE.invTypeInfo(.objectID(product.productType!.objectID)))
				return row.asAnyItem
			}
			if let products = products {
				rows.append(contentsOf: products)
			}
			
			let materials = (activity.requiredMaterials?.allObjects as? [SDEIndRequiredMaterial])?.filter {$0.materialType?.typeName != nil}.sorted {$0.materialType!.typeName! < $1.materialType!.typeName!}.map { material -> AnyTreeItem in
				let subtitle = UnitFormatter.localizedString(from: material.quantity, unit: .none, style: .long)
				let image = Image(material.materialType?.icon)
				
				let row = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute, title: material.materialType?.typeName, subtitle: subtitle, image: image, accessoryType: .disclosureIndicator), diffIdentifier: material.objectID, route: Router.SDE.invTypeInfo(.objectID(material.materialType!.objectID)))
				return row.asAnyItem
			}
			
			if let materials = materials, !materials.isEmpty {
				rows.append(Tree.Item.Section(Tree.Content.Section(title: NSLocalizedString("MATERIALS", comment: "")),
											  diffIdentifier: "\(activity.objectID).materials", treeController: view?.treeController, children: materials).asAnyItem)
			}
			
			if let requiredSkills = requiredSkillsPresentation(for: activity, character: character, context: context) {
				rows.append(requiredSkills.asAnyItem)
			}
			
			return Tree.Item.Section(Tree.Content.Section(title: activity.activity?.activityName?.uppercased()), diffIdentifier: activity.objectID, treeController: view?.treeController, children: rows).asAnyItem
		} ?? []
	}
	
	func whInfoPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> [AnyTreeItem] {
		guard let wh = type.wormhole else {return []}
		var rows = [AnyTreeItem]()
		
		if wh.targetSystemClass >= 0 {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Leads Into", comment: "").uppercased(),
														   subtitle: wh.targetSystemClassDisplayName,
														   image: Image(#imageLiteral(resourceName: "systems"))),
									  diffIdentifier: "LeadsInto").asAnyItem)
		}
		
		if wh.maxStableTime > 0 {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Maximum Stable Time", comment: "").uppercased(),
														   subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(wh.maxStableTime * 60), precision: .hours),
														   image: Image(context.eveIcon("22_32_16"))),
									  diffIdentifier: "MaximumStableTime").asAnyItem)
		}

		if wh.maxStableMass > 0 {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Maximum Stable Mass", comment: "").uppercased(),
														   subtitle: UnitFormatter.localizedString(from: wh.maxStableMass, unit: .kilogram, style: .long),
														   image: Image(context.eveIcon("2_64_10"))),
									  diffIdentifier: "MaximumStableMass").asAnyItem)
		}
		
		if wh.maxJumpMass > 0 {
			let frc = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(\SDEInvType.mass <= wh.maxJumpMass && \SDEInvType.group?.category?.categoryID == SDECategoryID.ship.rawValue && \SDEInvType.published == true)
				.sort(by: \SDEInvType.group?.groupName, ascending: true)
				.sort(by: \SDEInvType.typeName, ascending: true)
				.select([Self.as(NSManagedObjectID.self, name: "objectID"),
						 (\SDEInvType.group?.groupName).as(String.self, name: "groupName")])
				.fetchedResultsController(sectionName: (\SDEInvType.group?.groupName).as(String.self, name: "groupName"), cacheName: nil)
			try? frc.performFetch()
			let children = Tree.Item.FetchedResultsController<Tree.Item.NamedFetchedResultsSection<Tree.Item.InvType>>(frc, treeController: view?.treeController)
			
			rows.append (Tree.Item.ExpandableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																	  title: NSLocalizedString("Maximum Jump Mass", comment: "").uppercased(),
																	  subtitle: UnitFormatter.localizedString(from: wh.maxStableMass, unit: .kilogram, style: .long),
																	  image: Image(context.eveIcon("36_64_13"))),
												 diffIdentifier: "MaximumJumpMass",
												 isExpanded: false,
												 children: [children]).asAnyItem)
		}
		
		if wh.maxRegeneration > 0 {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Maximum Mass Regeneration", comment: "").uppercased(),
														   subtitle: UnitFormatter.localizedString(from: wh.maxRegeneration, unit: .kilogram, style: .long),
														   image: Image(context.eveIcon("23_64_3"))),
									  diffIdentifier: "MaximumMassRegeneration").asAnyItem)
		}
		return [Tree.Item.Virtual(children: rows, diffIdentifier: "WH").asAnyItem]
	}
	
	func npcInfoPresentation(for type: SDEInvType, character: Character?, context: SDEContext) -> [AnyTreeItem] {
		
		let results = context.managedObjectContext.from(SDEDgmTypeAttribute.self)
			.filter(\SDEDgmTypeAttribute.type == type && \SDEDgmTypeAttribute.attributeType?.published == true)
			.sort(by: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, ascending: true)
			.sort(by: \SDEDgmTypeAttribute.attributeType?.attributeID, ascending: true)
			.fetchedResultsController(sectionName: \SDEDgmTypeAttribute.attributeType?.attributeCategory?.categoryID, cacheName: nil)
		
		do {
			try results.performFetch()

			var sections = [AnyTreeItem]()
			
			results.sections?.forEach { section in
				guard let attributeCategory = (section.objects?.first as? SDEDgmTypeAttribute)?.attributeType?.attributeCategory else {return}
				
				let categoryID = SDEAttributeCategoryID(rawValue: attributeCategory.categoryID)
				
				let sectionTitle: String = categoryID == .null ? NSLocalizedString("Other", comment: "") : attributeCategory.categoryName ?? NSLocalizedString("Other", comment: "")
				
				var rows = [AnyTreeItem]()
				
				switch categoryID {
				case .turrets?:
					guard let speed = type[SDEAttributeID.speed] else {break}
					let damageMultiplier = type[SDEAttributeID.damageMultiplier]?.value ?? 1
					let maxRange = type[SDEAttributeID.maxRange]?.value ?? 0
					let falloff = type[SDEAttributeID.falloff]?.value ?? 0
					let duration: Double = speed.value / 1000
					
					let em = type[SDEAttributeID.emDamage]?.value ?? 0
					let explosive = type[SDEAttributeID.explosiveDamage]?.value ?? 0
					let kinetic = type[SDEAttributeID.kineticDamage]?.value ?? 0
					let thermal = type[SDEAttributeID.thermalDamage]?.value ?? 0
					let total = (em + explosive + kinetic + thermal) * damageMultiplier
					
					let interval = duration > 0 ? duration : 1
					let dps = total / interval
					
					rows.append(Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact,
																				em: em * damageMultiplier,
																				thermal: thermal * damageMultiplier,
																				kinetic: kinetic * damageMultiplier,
																				explosive: explosive * damageMultiplier), diffIdentifier: "Turrets").asAnyItem)
					
					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Damage per Second", comment: "").uppercased(),
																   subtitle: UnitFormatter.localizedString(from: dps, unit: .none, style: .long),
																   image: Image(#imageLiteral(resourceName: "turrets"))),
											  diffIdentifier: "TurretDamage").asAnyItem)
					
					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Rate of Fire", comment: "").uppercased(),
																   subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds),
																   image: Image(#imageLiteral(resourceName: "rateOfFire"))),
											  diffIdentifier: "TurretRoF").asAnyItem)
					
					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Optimal Range", comment: "").uppercased(),
																   subtitle: UnitFormatter.localizedString(from: maxRange, unit: .meter, style: .long),
																   image: Image(#imageLiteral(resourceName: "targetingRange"))),
											  diffIdentifier: "TurretOptimal").asAnyItem)
					
					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Falloff", comment: "").uppercased(),
																   subtitle: UnitFormatter.localizedString(from: falloff, unit: .meter, style: .long),
																   image: Image(#imageLiteral(resourceName: "falloff"))),
											  diffIdentifier: "TurretFalloff").asAnyItem)
					
				case .missile?:
					guard let attribute = type[SDEAttributeID.entityMissileTypeID], let missile = context.invType(Int(attribute.value)) else {break}
					
					rows.append(Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		   title: NSLocalizedString("Missile", comment: "").uppercased(),
																		   subtitle: missile.typeName,
																		   image: Image(missile.icon),
																		   accessoryType: .disclosureIndicator),
													  diffIdentifier: attribute.objectID,
													  route: Router.SDE.invTypeInfo(.objectID(missile.objectID))).asAnyItem)
					
					let duration: Double = (type[SDEAttributeID.missileLaunchDuration]?.value ?? 1000) / 1000
					let damageMultiplier = type[SDEAttributeID.missileDamageMultiplier]?.value ?? 1
					let velocityMultiplier = type[SDEAttributeID.missileEntityVelocityMultiplier]?.value ?? 1
					let flightTimeMultiplier = type[SDEAttributeID.missileEntityFlightTimeMultiplier]?.value ?? 1
					
					let em = missile[SDEAttributeID.emDamage]?.value ?? 0
					let explosive = missile[SDEAttributeID.explosiveDamage]?.value ?? 0
					let kinetic = missile[SDEAttributeID.kineticDamage]?.value ?? 0
					let thermal = missile[SDEAttributeID.thermalDamage]?.value ?? 0
					let total = (em + explosive + kinetic + thermal) * damageMultiplier
					
					let velocity: Double = (missile[SDEAttributeID.maxVelocity]?.value ?? 0) * velocityMultiplier
					let flightTime: Double = (missile[SDEAttributeID.explosionDelay]?.value ?? 1) * flightTimeMultiplier / 1000
					let agility: Double = missile[SDEAttributeID.agility]?.value ?? 0
					let mass = missile.mass
					
					let accelTime = min(flightTime, mass * agility / 1000000.0)
					let duringAcceleration = velocity / 2 * accelTime
					let fullSpeed = velocity * (flightTime - accelTime)
					let optimal = duringAcceleration + fullSpeed;
					
					let interval = duration > 0 ? duration : 1
					let dps = total / interval

					rows.append(Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact,
																				em: em * damageMultiplier,
																				thermal: thermal * damageMultiplier,
																				kinetic: kinetic * damageMultiplier,
																				explosive: explosive * damageMultiplier), diffIdentifier: "Missile").asAnyItem)

					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Damage per Second", comment: "").uppercased(),
																   subtitle: UnitFormatter.localizedString(from: dps, unit: .none, style: .long),
																   image: Image(#imageLiteral(resourceName: "launchers"))),
											  diffIdentifier: "MissileDamage").asAnyItem)

					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Rate of Fire", comment: "").uppercased(),
																   subtitle: TimeIntervalFormatter.localizedString(from: TimeInterval(duration), precision: .seconds),
																   image: Image(#imageLiteral(resourceName: "rateOfFire"))),
											  diffIdentifier: "MissileRoF").asAnyItem)

					rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																   title: NSLocalizedString("Optimal Range", comment: "").uppercased(),
																   subtitle: UnitFormatter.localizedString(from: optimal, unit: .meter, style: .long),
																   image: Image(#imageLiteral(resourceName: "targetingRange"))),
											  diffIdentifier: "MissileOptimal").asAnyItem)

					
				default:
					
					var resistanceRow: Tree.Item.DamageTypeRow?
					func resistance() -> Tree.Item.DamageTypeRow? {
						if resistanceRow == nil {
							resistanceRow = Tree.Item.DamageTypeRow(Tree.Content.DamageType(prototype: Prototype.DamageTypeCell.compact, unit: .percent, em: 0, thermal: 0, kinetic: 0, explosive: 0))
						}
						return resistanceRow
					}
					
					(section.objects as? [SDEDgmTypeAttribute])?.forEach { attribute in
						let value = attribute.value
						
						switch SDEAttributeID(rawValue: attribute.attributeType!.attributeID) {
						case .emDamageResonance?, .armorEmDamageResonance?, .shieldEmDamageResonance?,
							 .hullEmDamageResonance?, .passiveArmorEmDamageResonance?, .passiveShieldEmDamageResonance?:
							guard let row = resistance() else {return}
							row.content.em = max(row.content.em, 1 - value)
						case .thermalDamageResonance?, .armorThermalDamageResonance?, .shieldThermalDamageResonance?,
							 .hullThermalDamageResonance?, .passiveArmorThermalDamageResonance?, .passiveShieldThermalDamageResonance?:
							guard let row = resistance() else {return}
							row.content.thermal = max(row.content.thermal, 1 - value)
						case .kineticDamageResonance?, .armorKineticDamageResonance?, .shieldKineticDamageResonance?,
							 .hullKineticDamageResonance?, .passiveArmorKineticDamageResonance?, .passiveShieldKineticDamageResonance?:
							guard let row = resistance() else {return}
							row.content.kinetic = max(row.content.kinetic, 1 - value)
						case .explosiveDamageResonance?, .armorExplosiveDamageResonance?, .shieldExplosiveDamageResonance?,
							 .hullExplosiveDamageResonance?, .passiveArmorExplosiveDamageResonance?, .passiveShieldExplosiveDamageResonance?:
							guard let row = resistance() else {return}
							row.content.explosive = max(row.content.explosive, 1 - value)
						default:
							let row = Tree.Item.DgmAttributeRow(attribute: attribute, value: value, context: context)
							rows.append(row.asAnyItem)
						}
					}
					
					if let resistanceRow = resistanceRow {
						rows.append(resistanceRow.asAnyItem)
					}
					
					if categoryID == .shield {
						if let capacity = type[SDEAttributeID.shieldCapacity]?.value,
							let rechargeRate = type[SDEAttributeID.shieldRechargeRate]?.value,
							rechargeRate > 0 && capacity > 0 {
							let passive = 10.0 / (rechargeRate / 1000.0) * 0.5 * (1 - 0.5) * capacity
						
							rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		   title: NSLocalizedString("Passive Recharge Rate", comment: "").uppercased(),
																		   subtitle: UnitFormatter.localizedString(from: passive, unit: .hpPerSecond, style: .long),
																		   image: Image(#imageLiteral(resourceName: "shieldRecharge"))),
													  diffIdentifier: "ShieldRecharge").asAnyItem)

						}
						
						if let amount = type[SDEAttributeID.entityShieldBoostAmount]?.value,
							let duration = type[SDEAttributeID.entityShieldBoostDuration]?.value,
							duration > 0 && amount > 0 {
							
							let chance = (type[SDEAttributeID.entityShieldBoostDelayChance] ??
								type[SDEAttributeID.entityShieldBoostDelayChanceSmall] ??
								type[SDEAttributeID.entityShieldBoostDelayChanceMedium] ??
								type[SDEAttributeID.entityShieldBoostDelayChanceLarge])?.value ?? 0
							
							let repair = amount / (duration * (1 + chance) / 1000.0)

							rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		   title: NSLocalizedString("Repair Rate", comment: "").uppercased(),
																		   subtitle: UnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .long),
																		   image: Image(#imageLiteral(resourceName: "shieldBooster"))),
													  diffIdentifier: "ShieldBooster").asAnyItem)

						}
					}
					else if categoryID == .armor {
						if let amount = type[SDEAttributeID.entityArmorRepairAmount]?.value,
							let duration = type[SDEAttributeID.entityArmorRepairDuration]?.value,
							duration > 0 && amount > 0 {
							
							let chance = (type[SDEAttributeID.entityArmorRepairDelayChance] ??
								type[SDEAttributeID.entityArmorRepairDelayChanceSmall] ??
								type[SDEAttributeID.entityArmorRepairDelayChanceMedium] ??
								type[SDEAttributeID.entityArmorRepairDelayChanceLarge])?.value ?? 0
							
							let repair = amount / (duration * (1 + chance) / 1000.0)
							
							rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
																		   title: NSLocalizedString("Repair Rate", comment: "").uppercased(),
																		   subtitle: UnitFormatter.localizedString(from: repair, unit: .hpPerSecond, style: .long),
																		   image: Image(#imageLiteral(resourceName: "armorRepairer"))),
													  diffIdentifier: "ArmorRepair").asAnyItem)
							
						}
					}
				}
				
				guard !rows.isEmpty else {return}
				
				let section = Tree.Item.Section(Tree.Content.Section(title: sectionTitle.uppercased()),
												diffIdentifier: attributeCategory.objectID,
												treeController: view?.treeController,
												children: rows).asAnyItem
				
				if categoryID == .entityRewards {
					sections.insert(section, at: 0)
				}
				else {
					sections.append(section)
				}

			}
			
			return sections
		}
		catch {
			return []
		}
	}
}
