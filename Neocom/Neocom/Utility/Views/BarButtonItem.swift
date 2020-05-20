//
//  BarButtonItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/27/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI


enum BarButtonItems {
    static func close(_ action: @escaping () -> Void) -> some View {
        BarButtonItem(action: action) { Image(systemName: "xmark") }
    }
    
    static func trash(_ action: @escaping () -> Void) -> some View {
        BarButtonItem(action: action) { Image(systemName: "trash") }
    }
    
    static func actions(_ action: @escaping () -> Void) -> some View {
        BarButtonItem(action: action) { Image(systemName: "ellipsis") }
    }
    
    static func compose(_ action: @escaping () -> Void) -> some View {
        BarButtonItem(action: action) {
            Image(systemName: "square.and.pencil").offset(x: 1, y: -1)
        }
    }

}


struct BarButtonItem<Label: View>: View {
    var action: () -> Void
    var label: Label
    
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }
    
    
    var body: some View {
        Button(action: action) {
            label.frame(width: 30, height: 30)
                .background(Circle().foregroundColor(Color(.tertiarySystemFill)))
            .contentShape(Rectangle())
        }
    }
}

struct BarButtonItem_Previews: PreviewProvider {
    static var previews: some View {
        return NavigationView {
            VStack {
                Text("Text")
            }
            .navigationBarTitle(Text("Text"), displayMode: .inline)
            .navigationBarItems(leading: BarButtonItems.close {}, trailing: BarButtonItems.compose {})
            
        }//.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
}
