//
//  RuntimeError.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation

enum RuntimeError: Error {
    case unknown
    case noAccount
    case noResult
    case invalidOAuth2TOken
    case invalidGang
    case invalidPlanetLayout
    case invalidDNAFormat
    case invalidCharacterURL
    case invalidLoadoutFormat
    case invalidActivityType
    case missingCodingUserInfoKey(CodingUserInfoKey)
}
