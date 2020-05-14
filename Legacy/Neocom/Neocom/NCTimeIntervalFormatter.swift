//
//  NCTimeIntervalFormatter.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

class NCTimeIntervalFormatter: Formatter {
	enum Precision: Int {
		case seconds
		case minutes
		case hours
		case days
	};
	
	enum Format {
		case `default`
		case colonSeparated
	}
	
	var precision: Precision = .seconds
	var format: Format = .default

	class func localizedString(from timeInterval: TimeInterval, precision: Precision, format: Format = .default) -> String {
		let t = UInt(timeInterval.clamped(to: 0...Double(Int.max)))
		let d = t / (60 * 60 * 24);
		let h = (t / (60 * 60)) % 24;
		let m = (t / 60) % 60;
		let s = t % 60;
		
		if format == .colonSeparated {
			switch precision {
			case .days:
				return String(format: "%.2d:%.2d:%.2d:%.2d", d, h, m, s)
			case .hours:
				return String(format: "%.2d:%.2d:%.2d", h, m, s)
			case .minutes:
				return String(format: "%.2d:%.2d", m, s)
			case .seconds:
				return String(format: "%%.2d", m, s)
			}
		}
		else {
			var string = ""
			var empty = true
			
			if (precision.rawValue <= Precision.days.rawValue && d > 0) {
				string += "\(d)d"
				empty = false
			}
			if (precision.rawValue <= Precision.hours.rawValue && h > 0) {
				string += "\(empty ? "" : " ")\(h)h"
				empty = false
			}
			if (precision.rawValue <= Precision.minutes.rawValue && m > 0) {
				string += "\(empty ? "" : " ")\(m)m"
				empty = false
			}
			if (precision.rawValue <= Precision.seconds.rawValue && s > 0) {
				string += "\(empty ? "" : " ")\(s)s"
				empty = false
			}
			return empty ? "0s" : string;
		}
	}
	
	override func string(for obj: Any?) -> String? {
		guard let obj = obj as? TimeInterval else {return nil}
		return NCTimeIntervalFormatter.localizedString(from: obj, precision: precision)
	}
	
}
