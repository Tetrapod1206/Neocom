//
//  Config.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

struct Config: Hashable {
	struct ESI: Hashable {
		var clientID = "a0cc80b7006944249313dc22205ec645"
		var secretKey = "deUqMep7TONp68beUoC1c71oabAdKQOJdbiKpPcC"
		var callbackURL = URL(string: "eveauthnc://sso/")!
	}
	var esi = ESI()
	
	var maxCacheTime: TimeInterval = 3600 * 48
}


extension Config {
	static let current = Config()
}

enum URLScheme: String {
	case nc = "nc"
	case showinfo = "showinfo"
	case fitting = "fitting"
	case file = "file"
}
