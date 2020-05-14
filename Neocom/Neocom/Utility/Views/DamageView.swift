//
//  DamageView.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

extension DamageType {
    var accentColor: Color {
        switch self {
        case .em:
            return .emDamage
        case .thermal:
            return .thermalDamage
        case .kinetic:
            return .kineticDamage
        case .explosive:
            return .explosiveDamage
        }
    }
    
    var image: Image {
        switch self {
        case .em:
            return Image("em")
        case .thermal:
            return Image("thermal")
        case .kinetic:
            return Image("kinetic")
        case .explosive:
            return Image("explosion")
        }
    }
}

struct DamageView: View {
    let text: String
    let percent: Double
    let damageType: DamageType
    @inlinable init(_ text: String, percent: Double, damageType: DamageType) {
        self.text = text
        self.percent = percent
        self.damageType = damageType
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Icon(damageType.image, size: .small)
            Text(text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 18)
                .padding(.horizontal, 4)
                .background(ProgressView(progress: Float(percent)))
                .background(Color(.black))
                .foregroundColor(.white)
        }.accentColor(damageType.accentColor)
    }
}

struct DamageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                DamageView("25%", percent: 0.25, damageType: .em)
                DamageView("25%", percent: 0.25, damageType: .thermal)
                DamageView("25%", percent: 0.25, damageType: .kinetic)
                DamageView("25%", percent: 0.25, damageType: .explosive)
            }.padding().background(Color(.systemGroupedBackground)).colorScheme(.light).font(.footnote)
            HStack {
                DamageView("25%", percent: 0.25, damageType: .em)
                DamageView("25%", percent: 0.25, damageType: .thermal)
                DamageView("25%", percent: 0.25, damageType: .kinetic)
                DamageView("25%", percent: 0.25, damageType: .explosive)
            }.padding().background(Color(.systemGroupedBackground)).colorScheme(.dark).font(.footnote)
        }
    }
}
