//
//  ModernMenu.swift
//  Aerial Companion
//
//  Created by Guillaume Louel on 05/12/2020.
//

import SwiftUI

struct ModernMenu: View {
    @available(OSX 10.15.0, *)
    var body: some View {
        VStack {
            Button(action: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/{}/*@END_MENU_TOKEN@*/) {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Text("Button")/*@END_MENU_TOKEN@*/
            }
                    Text("Test Text")
                    Spacer()
                    HStack {
                        Text("Test Text")
                        Text("Test Text")
                    }
                    Spacer()
                    Text("Test Text")
        }
    }
}

struct ModernMenu_Previews: PreviewProvider {
    @available(OSX 10.15.0, *)
    static var previews: some View {
        ModernMenu()
    }
}
