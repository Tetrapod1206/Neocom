//
//  Array+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

extension Array where Element: Equatable {
	
	func transition(to: Array<Element>, handler: (_ oldIndex: Int?, _ newIndex: Int?, _ changeType: NSFetchedResultsChangeType) -> Void) {
		let from = self
		var arr = from
		
		var removed = IndexSet()
		var inserted = IndexSet()
		var updated = [(Int, Int)]()
		var moved = [(Int, Int)]()
		
		var j = 0
		for (i, v) in from.enumerated() {
			if to.count <= j || to[j] != v {
				arr.remove(at: i - removed.count)
				removed.insert(i)
			}
			else {
				updated.append((i, j))
				j += 1
			}
		}
		
		for (i, v) in to.enumerated() {
			if arr.count <= i || arr[i] != v {
				inserted.insert(i)
				arr.insert(v, at: i)
			}
		}
		
		for i in removed {
			let obj = from[i]
			for j in inserted {
				if obj == to[j] {
					removed.remove(i)
					inserted.remove(j)
					if i != j {
						moved.append((i, j))
					}
					else {
						updated.append((i, j))
					}
				}
			}
		}
		if !removed.isEmpty {
			removed.reversed().forEach {handler($0, nil, .delete)}
		}
		if !inserted.isEmpty {
			inserted.forEach {handler(nil, $0, .insert)}
		}
		if !moved.isEmpty {
			moved.reversed().forEach {handler($0.0, $0.1, .move)}
		}
		if !updated.isEmpty {
			updated.forEach {handler($0.0, $0.1, .update)}
		}
	}

	
	mutating func remove(at: IndexSet) {
		for i in at.reversed() {
			self.remove(at: i)
		}
	}
}

extension Array where Element: NSObject {
	
	/*func transition(to: Array<Element>, handler: (_ oldIndex: Int?, _ newIndex: Int?, _ changeType: NSFetchedResultsChangeType) -> Void) {
		let from = self
		var arr = from
		for i in (0..<from.count).reversed() {
			
			if to.index(where: {return from[i] === $0}) == nil {
				handler(i, nil, .delete)
				arr.remove(at: i)
			}
		}
		
		for i in 0..<to.count {
			let obj = to[i]
			if let j = arr.index(where: {return obj === $0}) {
				if j != i {
					handler(from.index(where: {return obj === $0}), i, .move)
				}
				else {
					handler(from.index(where: {return obj === $0}), i, .update)
				}
			}
			else {
				handler(nil, i, .insert)
			}
		}
	}*/
	
}

extension Array {
	func group(by closure: (Element, Element) -> Bool) -> [ArraySlice<Element>] {
		var copy = self
		var result = [ArraySlice<Element>]()
		let n = count
		var left = 0
		while left < n {
			let first = copy[left]
			let right = copy[left..<n].partition { (i) -> Bool in
				return !closure(first, i)
			}
			result.append(copy[left..<right])
			left = right
		}
		return result
	}
}
