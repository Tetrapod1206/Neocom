//
//  NCLoadout.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Dgmpp

//extension NCFittingEngine {
//	func sync<T>(execute block: @escaping () -> T) -> T {
//		var v: T?
//		performBlockAndWait {
//			v = block()
//		}
//		return v!
//	}
//}

enum NCFittingAccuracy {
	case none
	case low
	case average
	case good
}


class NCFittingLoadoutItem: NSObject, NSSecureCoding {
	let typeID: Int
	var count: Int
	let identifier: Int?
	
	public static var supportsSecureCoding: Bool {
		return true
	}
	
	init(type: DGMType, count: Int = 1) {
		self.typeID = type.typeID
		self.count = count
		self.identifier = type.identifier
		super.init()
	}
	
	init(typeID: Int, count: Int, identifier: Int? = nil) {
		self.typeID = typeID
		self.count = count
		self.identifier = identifier
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		typeID = aDecoder.decodeInteger(forKey: "typeID")
		count = aDecoder.containsValue(forKey: "count") ? aDecoder.decodeInteger(forKey: "count") : 1
		if let s = (aDecoder.decodeObject(forKey: "identifier") as? String) {
			identifier = Int(s) ?? s.hashValue
		}
		else {
			identifier = aDecoder.decodeInteger(forKey: "identifier")
		}
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(typeID, forKey: "typeID")
		if count != 1 {
			aCoder.encode(count, forKey: "count")
		}
		aCoder.encode(identifier, forKey: "identifier")
	}
	
	public static func ==(lhs: NCFittingLoadoutItem, rhs: NCFittingLoadoutItem) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	override var hashValue: Int {
		return [typeID, count].hashValue
	}
}

class NCFittingLoadoutModule: NCFittingLoadoutItem {
	let state: DGMModule.State
	let charge: NCFittingLoadoutItem?
	let socket: Int
	
	init(module: DGMModule) {
		state = module.preferredState
		if let charge = module.charge {
			self.charge = NCFittingLoadoutItem(type: charge, count: max(module.charges, 1))
		}
		else {
			self.charge = nil
		}
		socket = module.socket
		super.init(type: module)
	}
	
	init(typeID: Int, count: Int, identifier: Int?, state: DGMModule.State = .active, charge: NCFittingLoadoutItem? = nil, socket: Int = -1) {
		self.state = state
		self.charge = charge
		self.socket = socket
		super.init(typeID: typeID, count: count, identifier: identifier)
	}
	
	required init?(coder aDecoder: NSCoder) {
		state = DGMModule.State(rawValue: aDecoder.decodeInteger(forKey: "state")) ?? .unknown
		charge = aDecoder.decodeObject(forKey: "charge") as? NCFittingLoadoutItem
		socket = aDecoder.containsValue(forKey: "socket") ? aDecoder.decodeInteger(forKey: "socket") : -1
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(state.rawValue, forKey: "state")
		aCoder.encode(charge, forKey: "charge")
		aCoder.encode(socket, forKey: "socket")
	}

	override var hashValue: Int {
		return [typeID, count, state.rawValue, charge?.typeID ?? 0].hashValue
	}
}

class NCFittingLoadoutDrone: NCFittingLoadoutItem {
	let isActive: Bool
	let squadronTag: Int
	
	init(typeID: Int, count: Int, identifier: Int?, isActive: Bool = true, squadronTag: Int = -1) {
		self.isActive = isActive
		self.squadronTag = squadronTag
		super.init(typeID: typeID, count: count, identifier: identifier)
	}
	
	init(drone: DGMDrone) {
		self.isActive = drone.isActive
		self.squadronTag = drone.squadronTag
		super.init(type: drone)
	}

	required init?(coder aDecoder: NSCoder) {
		isActive = aDecoder.containsValue(forKey: "isActive") ? aDecoder.decodeBool(forKey: "isActive") : true
		squadronTag = aDecoder.containsValue(forKey: "squadronTag") ? aDecoder.decodeInteger(forKey: "squadronTag") : -1
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		if !isActive {
			aCoder.encode(isActive, forKey: "isActive")
		}
		aCoder.encode(squadronTag, forKey: "squadronTag")
	}

	override var hashValue: Int {
		return [typeID, count, isActive ? 1 : 0].hashValue
	}
}


public class NCFittingLoadout: NSObject, NSSecureCoding {
	var modules: [DGMModule.Slot: [NCFittingLoadoutModule]]?
	var drones: [NCFittingLoadoutDrone]?
	var cargo: [NCFittingLoadoutItem]?
	var implants: [NCFittingLoadoutItem]?
	var boosters: [NCFittingLoadoutItem]?
	
	override init() {
		super.init()
	}
	
	public static var supportsSecureCoding: Bool {
		return true
	}

	
	public required init?(coder aDecoder: NSCoder) {
		modules = [DGMModule.Slot: [NCFittingLoadoutModule]]()
		for (key, value) in aDecoder.decodeObject(forKey: "modules") as? [Int: [NCFittingLoadoutModule]] ?? [:] {
			guard let key = DGMModule.Slot(rawValue: key) else {continue}
			modules?[key] = value
		}
		
		drones = aDecoder.decodeObject(forKey: "drones") as? [NCFittingLoadoutDrone]
		cargo = aDecoder.decodeObject(forKey: "cargo") as? [NCFittingLoadoutItem]
		implants = aDecoder.decodeObject(forKey: "implants") as? [NCFittingLoadoutItem]
		boosters = aDecoder.decodeObject(forKey: "boosters") as? [NCFittingLoadoutItem]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		var dic = [Int: [NCFittingLoadoutModule]]()
		for (key, value) in modules ?? [:] {
			dic[key.rawValue] = value
		}
		
		aCoder.encode(dic, forKey:"modules")

		if drones?.count ?? 0 > 0 {
			aCoder.encode(drones, forKey: "drones")
		}
		if cargo?.count ?? 0 > 0 {
			aCoder.encode(cargo, forKey: "cargo")
		}
		if implants?.count ?? 0 > 0 {
			aCoder.encode(implants, forKey: "implants")
		}
		if boosters?.count ?? 0 > 0 {
			aCoder.encode(boosters, forKey: "boosters")
		}
	}
}

extension DGMModule {
	func accuracy(targetSignature: DGMMeter, hitChance: DGMPercent = 0.75) -> NCFittingAccuracy{
		guard let ship = parent as? DGMShip else {return .none}
		
		let optimal = self.optimal
		let falloff = self.falloff
		let angularVelocity = self.angularVelocity(targetSignature: targetSignature, hitChance: hitChance) * DGMSeconds(1)
		let v0 = ship.maxVelocityInOrbit(optimal) * DGMSeconds(1)
		let v1 = ship.maxVelocityInOrbit(optimal + falloff) * DGMSeconds(1)
		if angularVelocity * optimal > v0 {
			return .good
		}
		else if angularVelocity * (optimal + falloff) > v1 {
			return .average
		}
		else {
			return .low
		}
	}
}


extension DGMModule.Slot {
	var image: UIImage? {
		switch self {
		case .hi:
			return #imageLiteral(resourceName: "slotHigh")
		case .med:
			return #imageLiteral(resourceName: "slotMed")
		case .low:
			return #imageLiteral(resourceName: "slotLow")
		case .rig:
			return #imageLiteral(resourceName: "slotRig")
		case .subsystem:
			return #imageLiteral(resourceName: "slotSubsystem")
		case .service:
			return #imageLiteral(resourceName: "slotService")
		case .mode:
			return #imageLiteral(resourceName: "slotSubsystem")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .hi:
			return NSLocalizedString("Hi Slot", comment: "")
		case .med:
			return NSLocalizedString("Med Slot", comment: "")
		case .low:
			return NSLocalizedString("Low Slot", comment: "")
		case .rig:
			return NSLocalizedString("Rig Slot", comment: "")
		case .subsystem:
			return NSLocalizedString("Subsystem Slot", comment: "")
		case .service:
			return NSLocalizedString("Service Slot", comment: "")
		case .mode:
			return NSLocalizedString("Tactical Mode", comment: "")
		default:
			return nil
		}
	}
	
	var name: String? {
		switch self {
		case .hi:
			return "Hi Slot"
		case .med:
			return "Med Slot"
		case .low:
			return "Low Slot"
		case .rig:
			return "Rig Slot"
		case .subsystem:
			return "Subsystem Slot"
		case .service:
			return "Service Slot"
		case .mode:
			return "Tactical Mode"
		default:
			return nil
		}
	}
	
	init?(name: String) {
		if name.range(of: "hi slot")?.lowerBound == name.startIndex {
			self = .hi
		}
		else if name.range(of: "med slot")?.lowerBound == name.startIndex {
			self = .med
		}
		else if name.range(of: "low slot")?.lowerBound == name.startIndex {
			self = .low
		}
		else if name.range(of: "rig slot")?.lowerBound == name.startIndex {
			self = .rig
		}
		else if name.range(of: "subsystem slot")?.lowerBound == name.startIndex {
			self = .subsystem
		}
		else if name.range(of: "service slot")?.lowerBound == name.startIndex {
			self = .service
		}
		else {
			return nil
		}
	}
}

extension DGMModule.State {
	var image: UIImage? {
		switch self {
		case .offline:
			return #imageLiteral(resourceName: "offline")
		case .online:
			return #imageLiteral(resourceName: "online")
		case .active:
			return #imageLiteral(resourceName: "active")
		case .overloaded:
			return #imageLiteral(resourceName: "overheated")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .offline:
			return NSLocalizedString("Offline", comment: "")
		case .online:
			return NSLocalizedString("Online", comment: "")
		case .active:
			return NSLocalizedString("Active", comment: "")
		case .overloaded:
			return NSLocalizedString("Overheated", comment: "")
		default:
			return nil
		}
	}
}

extension DGMShip.ScanType {
	var image: UIImage? {
		switch self {
		case .gravimetric:
			return #imageLiteral(resourceName: "gravimetric")
		case .magnetometric:
			return #imageLiteral(resourceName: "magnetometric")
		case .ladar:
			return #imageLiteral(resourceName: "ladar")
		case .radar:
			return #imageLiteral(resourceName: "radar")
		case .multispectral:
			return #imageLiteral(resourceName: "multispectral")
		}
	}
	
	var title: String? {
		switch self {
		case .gravimetric:
			return NSLocalizedString("Gravimetric", comment: "")
		case .magnetometric:
			return NSLocalizedString("Magnetometric", comment: "")
		case .ladar:
			return NSLocalizedString("Ladar", comment: "")
		case .radar:
			return NSLocalizedString("Radar", comment: "")
		case .multispectral:
			return NSLocalizedString("Multispectral", comment: "")
		}
	}
}

extension DGMDrone.Squadron {
	var title: String? {
		switch self {
		case .heavy:
			return NSLocalizedString("Heavy", comment: "")
		case .light:
			return NSLocalizedString("Light", comment: "")
		case .support:
			return NSLocalizedString("Support", comment: "")
		case .none:
			return NSLocalizedString("Drone", comment: "")
		}
	}
}

extension NCFittingAccuracy {
	var color: UIColor {
		switch self {
		case .none:
			return .white
		case .low:
			return .red
		case .average:
			return .yellow
		case .good:
			return .green
		}
	}
}

extension DGMDamageVector: Hashable {
	public var hashValue: Int {
		return [em, kinetic, thermal, explosive].hashValue
	}
	
	public static func == (lhs: DGMDamageVector, rhs: DGMDamageVector) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

extension DGMCharacter {

	func setSkills(levels: [Int: Int]) {
		skills.forEach {
			$0.level = levels[$0.typeID] ?? 0
		}
	}

	var loadout: NCFittingLoadout {
		get {
			let ship = self.ship ?? self.structure
			let loadout = NCFittingLoadout()
			loadout.implants = implants.map{ NCFittingLoadoutItem(type: $0) }
			loadout.boosters = boosters.map{ NCFittingLoadoutItem(type: $0) }
			
			var drones = [Int: NCFittingLoadoutDrone]()
			for drone in ship?.drones ?? [] {
				let identifier = drone.identifier
				
				if (drones[identifier]?.count += 1) == nil {
					drones[identifier] = NCFittingLoadoutDrone(drone: drone)
				}
			}
			
			loadout.drones = Array(drones.values)
			
			var modules = [DGMModule.Slot: [NCFittingLoadoutModule]]()
			
			for module in ship?.modules ?? [] {
				modules[module.slot, default: []].append(NCFittingLoadoutModule(module: module))
			}
			
			loadout.modules = modules
			
			return loadout
		}
		set {
			let ship = (self.ship ?? self.structure)!
			for implant in newValue.implants ?? [] {
				try? add(DGMImplant(typeID: implant.typeID))
			}
			for booster in newValue.boosters ?? [] {
				try? add(DGMBooster(typeID: booster.typeID))
			}
			for drone in newValue.drones ?? [] {
				do {
					let identifier = drone.identifier ?? UUID().hashValue
					for _ in 0..<drone.count {
						let item = try DGMDrone(typeID: drone.typeID)
						try ship.add(item, squadronTag: drone.squadronTag)
						item.isActive = drone.isActive
						item.identifier = identifier
					}
				}
				catch {
				}
			}
			for (_, modules) in newValue.modules?.sorted(by: { $0.key.rawValue > $1.key.rawValue }) ?? [] {
				for module in modules {
					do {
						let identifier = module.identifier ?? UUID().hashValue
						for _ in 0..<module.count {
							let item = try DGMModule(typeID: module.typeID)
							try ship.add(item, socket: module.socket)
							item.identifier = identifier
							item.state = module.state
							if let charge = module.charge {
								try item.setCharge(DGMCharge(typeID: charge.typeID))
							}
						}
					}
					catch {
					}
				}
			}
		}
	}
	
	class func url(account: NCAccount) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
		components.scheme = NCURLScheme.nc.rawValue
		components.host = "character"
		
		var queryItems = [URLQueryItem(name: "accountUUID", value: uuid)]
		
		if let name = account.characterName {
			queryItems.append(URLQueryItem(name: "name", value: name))
		}
		queryItems.append(URLQueryItem(name: "characterID", value: "\(account.characterID)"))
		
		components.queryItems = queryItems
		return components.url!
	}

	class func url(level: Int) -> URL {
		var components = URLComponents()
		components.scheme = NCURLScheme.nc.rawValue
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "level", value: String(level)),
			URLQueryItem(name: "name", value: NSLocalizedString("All Skills", comment: "") + " " + String(romanNumber: level))
		]
		return components.url!
	}

	class func url(character: NCFitCharacter) -> URL? {
		guard let uuid = character.uuid else {return nil}
		var components = URLComponents()
		components.scheme = NCURLScheme.nc.rawValue
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "characterUUID", value: uuid),
			URLQueryItem(name: "name", value: character.name ?? "")
		]
		return components.url!
	}

	var url: URL? {
		return URL(string: name)
	}
	
	var account: NCAccount? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let accountUUID = components.queryItems?.first(where: {$0.name == "accountUUID"})?.value else {return nil}
		return NCStorage.sharedStorage?.accounts[accountUUID]
	}

	var fitCharacter: NCFitCharacter? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let characterUUID = components.queryItems?.first(where: {$0.name == "characterUUID"})?.value else {return nil}
		let character: NCFitCharacter? = NCStorage.sharedStorage?.viewContext.fetch("FitCharacter", where: "uuid == %@", characterUUID)
		return character
	}

	var level: Int? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let level = components.queryItems?.first(where: {$0.name == "level"})?.value else {return nil}
		return Int(level)
	}
	
	func setSkills(from url: URL, completionHandler: ((Bool) -> Void)? = nil) {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
			let queryItems = components.queryItems,
			components.scheme == NCURLScheme.nc.rawValue,
			components.host == "character" else {
			completionHandler?(false)
			return
		}

		if let item = queryItems.first(where: {$0.name == "accountUUID"}), let uuid = item.value {
			NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
				
				if let account = NCAccount.accounts(managedObjectContext: managedObjectContext)[uuid] {
					self.setSkills(from: account, completionHandler: completionHandler)
				}
				else {
					DispatchQueue.main.async {
						completionHandler?(false)
					}
				}

			}
		}
		else if let item = queryItems.first(where: {$0.name == "characterUUID"}), let uuid = item.value {
			NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
				
				if let character = NCFitCharacter.fitCharacters(managedObjectContext: managedObjectContext)[uuid] {
					self.setSkills(from: character, completionHandler: completionHandler)
				}
				else {
					DispatchQueue.main.async {
						completionHandler?(false)
					}
				}
				
			}
		}
		else if let item = queryItems.first(where: {$0.name == "level"}), let level = Int(item.value ?? ""){
			setSkills(level: level, completionHandler: completionHandler)
		}
		else {
			DispatchQueue.main.async {
				completionHandler?(false)
			}
		}
	}

	
	func setSkills(from account: NCAccount, completionHandler: ((Bool) -> Void)? = nil) {
		let url = DGMCharacter.url(account: account)
		NCDataManager(account: account, cachePolicy: .returnCacheDataElseLoad).skills { result in
			switch result {
			case let .success(value, _):
				var levels = [Int: Int]()
				for skill in value.skills ?? [] {
					guard let skillID = skill.skillID, let currentSkillLevel = skill.currentSkillLevel else {continue}
					levels[skillID] = currentSkillLevel
				}
				self.setSkills(levels: levels)
				self.name = url?.absoluteString ?? ""
				completionHandler?(true)

			default:
				completionHandler?(false)
			}
		}
	}
	
	@nonobjc func setSkills(from character: NCFitCharacter, completionHandler: ((Bool) -> Void)? = nil) {
		let url = DGMCharacter.url(character: character)
		let skills = character.skills ?? [:]
		setSkills(levels: skills)
		name = url?.absoluteString ?? ""
		completionHandler?(true)
	}

	
	@nonobjc func setSkills(level: Int, completionHandler: ((Bool) -> Void)? = nil) {
		let url = DGMCharacter.url(level: level)
		setSkillLevels(level)
		name = url.absoluteString
		completionHandler?(true)
	}
	
	var shoppingItem: NCShoppingItem? {
		guard let context = NCStorage.sharedStorage?.viewContext else {return nil}
		guard let ship = self.ship ?? self.structure else {return nil}
		let loadout = self.loadout
		let shipItem = NCShoppingItem(entity: NSEntityDescription.entity(forEntityName: "ShoppingItem", in: context)!, insertInto: nil)
		shipItem.typeID = Int32(ship.typeID)
		shipItem.quantity = 1
		shipItem.identifier = "\(identifier)"
		shipItem.name = ship.name
		
		var cargo = [Int: Int]()
		loadout.modules?.forEach { (slot, modules) in
			let flag: NCItemFlag
			switch slot {
			case .hi:
				flag = .hiSlot
			case .med:
				flag = .medSlot
			case .low:
				flag = .lowSlot
			case .rig:
				flag = .rigSlot
			case .subsystem:
				flag = .subsystemSlot
			case .service:
				flag = .service
			default:
				return
			}
			var items = [Int: Int]()
			modules.forEach {
				items[$0.typeID] = (items[$0.typeID] ?? 0) + max($0.count, 1)
				if let charge = $0.charge {
					cargo[charge.typeID] = (cargo[charge.typeID] ?? 0) + max(charge.count, 1)
				}
			}
			items.forEach { i in
				let item = NCShoppingItem(entity: NSEntityDescription.entity(forEntityName: "ShoppingItem", in: context)!, insertInto: nil)
				item.flag = flag.rawValue
				item.typeID = Int32(i.key)
				item.quantity = Int32(i.value)
				shipItem.addToContents(item)
			}
		}
		
		var drones = [Int: Int]()
		loadout.drones?.forEach {
			drones[$0.typeID] = (drones[$0.typeID] ?? 0) + $0.count
		}
		
		drones.forEach { i in
			let item = NCShoppingItem(entity: NSEntityDescription.entity(forEntityName: "ShoppingItem", in: context)!, insertInto: nil)
			item.flag = NCItemFlag.drone.rawValue
			item.typeID = Int32(i.key)
			item.quantity = Int32(i.value)
			shipItem.addToContents(item)
		}

		cargo.forEach { i in
			let item = NCShoppingItem(entity: NSEntityDescription.entity(forEntityName: "ShoppingItem", in: context)!, insertInto: nil)
			item.flag = NCItemFlag.cargo.rawValue
			item.typeID = Int32(i.key)
			item.quantity = Int32(i.value)
			shipItem.addToContents(item)
		}

		return shipItem
	}

}

