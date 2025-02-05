//
//  FunctionBoxes.swift
//  Add-to-Album
//
//  Created by Alfonso Fiore on 5/2/25.
//

import SwiftUI

struct FunctionBox: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.5)) // 50% transparent black box
            .cornerRadius(10)
    }
}
