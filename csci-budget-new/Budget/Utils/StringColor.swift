//
//  StringColor.swift
//  Budget
//
//  Created by Arthur Guiot on 11/20/24.
//
import SwiftUI

extension String {
    /// Generates a consistent color from a string using hashing
    var toColor: Color {
        // Create a deterministic hash value from the string
        let hash = self.utf8.reduce(5381) { ($0 << 5) &+ $0 &+ Int64($1) }
        
        let shift: Int64 = 200
        // Use golden ratio to help spread the hue values nicely
        let goldenRatio = 0.618033988749895
        
        // Use the hash to generate a float between 0 and 1
        let hueValue = Double(abs(hash + shift) % 1000) / 1000.0
        
        // Offset the hue by golden ratio and wrap around 1.0
        let adjustedHue = (hueValue + goldenRatio).truncatingRemainder(dividingBy: 1.0)
        
        // Use carefully chosen saturation and brightness values for pleasant colors
        return Color(hue: adjustedHue,
                     saturation: 0.9, // High enough for vibrant colors but not too harsh
                     brightness: 0.9)  // Bright enough to be visible but not too light
    }
}

struct ColorTestView: View {
    let testStrings = [
        "Airlines and Aviation Services",
        "Uncategorized",
        "Taxi"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("String to Color Test")
                    .font(.title)
                    .padding()
                
                // Test cases with labels
                ForEach(testStrings, id: \.self) { str in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(str.toColor)
                            .frame(width: 100, height: 40)
                        
                        Text(str)
                            .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Grid demonstration
                Text("Color Grid")
                    .font(.title2)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(1...16, id: \.self) { num in
                        RoundedRectangle(cornerRadius: 8)
                            .fill("Test\(num)".toColor)
                            .frame(height: 60)
                            .overlay(
                                Text("\(num)")
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding()
            }
        }
    }
}

// Preview
#Preview("Color Test") {
    ColorTestView()
}

// Dark mode preview
#Preview("Color Test (Dark)") {
    ColorTestView()
        .preferredColorScheme(.dark)
}

// Different device sizes
#Preview("Color Test (iPad)") {
    ColorTestView()
}
