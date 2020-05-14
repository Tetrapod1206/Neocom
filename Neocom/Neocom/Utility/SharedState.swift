//
//  SharedState.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/14/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible
import EVEAPI
import Combine

class SharedState: ObservableObject {
    @Published var account: Account? {
        willSet {
            objectWillChange.send()
        }
        didSet {
            accountID = account?.uuid
            _esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
        }
    }
    
    private var _esi: ESI?
    
    var esi: ESI {
        return _esi!
    }
    
    let objectWillChange = ObjectWillChangePublisher()
    
    @UserDefault(key: .activeAccountID) private var accountID: String? = nil
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.account = try? managedObjectContext.from(Account.self).filter(/\Account.uuid == accountID).first()
        _esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()
    }
    
    @Published var userActivity: NSUserActivity?
}
