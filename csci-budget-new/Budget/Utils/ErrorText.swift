//
//  ErrorText.swift
//  Budget
//
//  Created by Arthur Guiot on 10/21/24.
//

import SwiftUI

// This view constructs and formats error messages.
struct ErrorText: View {
    let error: Error
    
    init(_ error: Error) {
        self.error = error
        
        debug(error.localizedDescription)
    }
    
    var body: some View {
        Text(error.localizedDescription)
            .foregroundColor(.red)
            .font(.footnote)
    }
}

struct ErrorText_Previews: PreviewProvider {
    static var previews: some View {
        ErrorText(NSError())
    }
}
