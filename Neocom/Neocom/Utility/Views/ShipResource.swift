//
//  ShipResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct ShipResource: View {
    enum Style {
        case progress
        case counter
    }

    var used: Double
    var total: Double
    var unit: UnitFormatter.Unit
    var image: Image
    var style: Style
    var format: UnitFormatter.Style
    
    init(used: Double, total: Double, unit: UnitFormatter.Unit, image: Image, style: Style, format: UnitFormatter.Style = .short) {
        self.used = used
        self.total = total
        self.unit = unit
        self.image = image
        self.style = style
        self.format = format
    }

    init(used: Int, total: Int, unit: UnitFormatter.Unit, image: Image, style: Style, format: UnitFormatter.Style = .short) {
        self.used = Double(used)
        self.total = Double(total)
        self.unit = unit
        self.image = image
        self.style = style
        self.format = format
    }

    var body: some View {
        Group {
            if style == .progress {
                HStack(spacing: 2) {
                    Icon(image, size: .small)
                    Text("\(UnitFormatter.localizedString(from: used, unit: .none, style: format))/\(UnitFormatter.localizedString(from: total, unit: unit, style: format))")
                        .foregroundColor(used <= total ? .primary : .red)
                        .frame(maxWidth: .infinity)
                        .padding(2)
                        .background(ProgressView(progress: Float(total > 0 ? used / total : 0).clamped(to: 0...1)))
                        .accentColor(.skyBlueBackground)
                }
            }
            else {
                HStack() {
                    Icon(image, size: .small)
                    Text("\(UnitFormatter.localizedString(from: used, unit: .none, style: format))/\(UnitFormatter.localizedString(from: total, unit: unit, style: format))")
                    .foregroundColor(used <= total ? .primary : .red)
//                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }.font(.caption)
    }
}

struct ShipResource_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ShipResource(used: 100, total: 200, unit: .teraflops, image: Image("cpu"), style: .progress)
            ShipResource(used: 100, total: 200, unit: .teraflops, image: Image("cpu"), style: .counter)
        }
    }
}
