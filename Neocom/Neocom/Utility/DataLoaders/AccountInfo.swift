//
//  AccountInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Alamofire
import Expressible
import Combine
import CoreData

class AccountInfo: ObservableObject {
    @Published var skillQueue: Result<[ESI.Characters.CharacterID.Skillqueue.Success], AFError>?
    @Published var ship: Result<ESI.Characters.CharacterID.Ship.Success, AFError>?
    @Published var location: Result<SDEMapSolarSystem, AFError>?
    @Published var totalSP: Result<Int64, AFError>?
    @Published var balance: Result<Double, AFError>?

    let characterInfo: CharacterInfo
    
    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext, characterImageSize: ESI.Image.Size? = nil, corporationImageSize: ESI.Image.Size? = nil, allianceImageSize: ESI.Image.Size? = nil) {
        characterInfo = CharacterInfo(esi: esi, characterID: characterID, characterImageSize: characterImageSize, corporationImageSize: corporationImageSize, allianceImageSize: allianceImageSize)
        
        let subject = objectWillChange
        characterInfo.objectWillChange.sink {
            subject.send()
        }.store(in: &subscriptions)

        let character = esi.characters.characterID(Int(characterID))
        
        character.ship().get()
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.ship = result
        }.store(in: &subscriptions)

        character.skills().get()
            .map{$0.totalSP}
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.totalSP = result
        }.store(in: &subscriptions)
        
        character.wallet().get()
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.balance = result
        }.store(in: &subscriptions)

        character.location().get().receive(on: DispatchQueue.main).compactMap { location in
            try? managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == Int32(location.solarSystemID)).first()
        }
        .asResult()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            self?.location = result
        }.store(in: &subscriptions)
        
        character.skillqueue().get()
            .map{$0.filter{$0.finishDate.map{$0 > Date()} == true}}
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.skillQueue = result
        }.store(in: &subscriptions)

    }
    
    private var subscriptions: [AnyCancellable] = []
}
