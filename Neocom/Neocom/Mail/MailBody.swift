//
//  MailBody.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Combine
import CoreData
import Alamofire

struct MailBody: View {
    @Binding var mail: ESI.MailHeaders.Element
    var contacts: [Int64: Contact]
    
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject private var mailBody = Lazy<DataLoader<ESI.MailBody, AFError>, Never>()
//    @State private var markReadPublisher: AnyPublisher<Void, Never>? = nil
    
    var body: some View {
        let result = sharedState.account.flatMap {account in
            mail.mailID.map { mailID in
                mailBody.get(initial: DataLoader(sharedState.esi.characters.characterID(Int(account.characterID)).mail().mailID(mailID).get()
                    .map{$0.value}
                    .receive(on: RunLoop.main)))
            }
        }
        let body = result?.result?.value
        let error = result?.result?.error
        return Group {
            if body != nil {
                MailBodyContent(mailBody: body!, contacts: contacts)
//                    .onAppear {
//                        guard let account = self.sharedState.account, let mailID = self.mail.mailID, self.mail.isRead != true else {return}
//                        self.markReadPublisher = self.sharedState.esi.characters.characterID(Int(account.characterID)).mail().mailID(mailID).put(contents: ESI.Characters.CharacterID.Mail.MailID.Contents(labels: self.mail.labels, read: true)).receive(on: RunLoop.main)
//                            .map{_ in}
//                            .catch{_ in Empty()}
//                            .eraseToAnyPublisher()
//                }
//                .onReceive(markReadPublisher ?? Empty().eraseToAnyPublisher()) {
////                    self.markReadPublisher = nil
//                    self.mail.isRead = true
//                }
            }
            else if error != nil {
                Text(error!).padding()
            }
        }
//        .navigationBarTitle(mail.subject ?? "Mail")
    }
}

struct MailBodyContent: View {
    var mailBody: ESI.MailBody
    var contacts: [Int64: Contact]
    
    private var from: some View {
        mailBody.from.flatMap {
            contacts[Int64($0)]?.name
        }.map {
            Text($0)
        }
    }
    
    private var to: Text {
        (mailBody.recipients?.compactMap {contacts[Int64($0.recipientID)]?.name}.joined(separator: ", ")).map {
            Text($0)
        } ?? Text("Unknown")
    }
    
    var body: some View {
        let text = try? NSMutableAttributedString(data: mailBody.body?.data(using: .utf8) ?? Data(),
                                      options: [.documentType : NSAttributedString.DocumentType.html,
                                                .characterEncoding: String.Encoding.utf8.rawValue,
                                                .defaultAttributes: [:]],
                                      documentAttributes: nil)
        text?.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: text?.length ?? 0))
        text?.removeAttribute(.font, range: NSRange(location: 0, length: text?.length ?? 0))
        text?.removeAttribute(.paragraphStyle, range: NSRange(location: 0, length: text?.length ?? 0))
        text?.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: text?.length ?? 0))
        return GeometryReader { geometry in
            text.map { body in
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            (self.mailBody.from.map{Avatar(characterID: Int64($0), size: .size128)} ?? Avatar(image: nil))
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                self.from.font(.headline)
                                Group {
                                    (Text("To: ") + self.to.foregroundColor(.secondary))
//                                    self.mailBody.subject.map{Text("Subject: ") + Text($0).foregroundColor(.secondary)}
                                    self.mailBody.timestamp.map { date in
                                        Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)).foregroundColor(.secondary)
                                    }
                                }.font(.subheadline)
                            }
                        }.padding(.horizontal)
                        
                        Divider()
                        AttributedText(body, preferredMaxLayoutWidth: geometry.size.width - 32).padding(.horizontal, 16)
                    }
                }
            }
        }
        .navigationBarTitle(mailBody.subject ?? "Mail")

    }
}

#if DEBUG
struct MailBody_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount

        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.sharedStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = "Artem Valiant"
        contact.contactID = 1554561480

        let recipient = ESI.Characters.CharacterID.Mail.Recipient(recipientID: Int(contact.contactID), recipientType: .character)
        let body = ESI.MailBody(body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                     from: Int(contact.contactID),
                     labels: [1],
                     read: false,
                     recipients: repeatElement(recipient, count: 4).map{$0},
                     subject: "Mail Subject",
                     timestamp: Date())
        
        return
            NavigationView {
                MailBodyContent(mailBody: body, contacts: [contact.contactID: contact])
            }
            .environmentObject(SharedState.testState())
    }
}
#endif
