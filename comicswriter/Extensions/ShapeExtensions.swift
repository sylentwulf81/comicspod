import SwiftUI

extension Shape {
    func strokeBorder<S>(_ content: S, lineWidth: CGFloat = 1) -> some View where S: ShapeStyle {
        stroke(content, lineWidth: lineWidth)
    }
}

extension InsettableShape {
    func fillStrokeBorder<S1, S2>(_ fillContent: S1, _ strokeContent: S2, lineWidth: CGFloat = 1) -> some View where S1: ShapeStyle, S2: ShapeStyle {
        self.fill(fillContent)
            .stroke(strokeContent, lineWidth: lineWidth)
    }
} 