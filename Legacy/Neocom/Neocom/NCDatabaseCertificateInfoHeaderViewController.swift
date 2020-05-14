//
//  NCDatabaseCertificateInfoHeaderViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDatabaseCertificateInfoHeaderViewController: UIViewController {
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var textView: UITextView!
	
	var certificate: NCDBCertCertificate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
		titleLabel.text = certificate?.certificateName
		textView.attributedText = certificate?.certificateDescription?.text?.withFont(textView.font!, textColor: textView.textColor!)
		imageView.image = NCDBEveIcon.icon(file: NCDBEveIcon.File.certificateUnclaimed.rawValue)?.image?.image
		
		guard let certificate = certificate else {return}

		NCDatabase.sharedDatabase!.performBackgroundTask { context in
			guard let certificate = (try? context.existingObject(with: certificate.objectID)) as? NCDBCertCertificate else {return}
			let character = (try? NCCharacter.load(account: NCAccount.current).get()) ?? NCCharacter()
			let trainingQueue = NCTrainingQueue(character: character)
			var level: NCDBCertMasteryLevel?
			for mastery in (certificate.masteries?.sortedArray(using: [NSSortDescriptor(key: "level.level", ascending: true)]) as? [NCDBCertMastery]) ?? [] {
				trainingQueue.add(mastery: mastery)
				if !trainingQueue.skills.isEmpty {
					break
				}
				level = mastery.level
			}
			
			if let image = level?.icon?.image?.image {
				DispatchQueue.main.async {
					self.imageView.image = image
				}
			}
		}
	}

}
