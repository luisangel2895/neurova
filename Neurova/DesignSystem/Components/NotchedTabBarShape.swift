import SwiftUI

struct NotchedTabBarShape: Shape {
    var cornerRadius: CGFloat = NRadius.navigationBar
    var notchRadius: CGFloat = 33.5
    var notchHorizontalScale: CGFloat = 1.1

    func path(in rect: CGRect) -> Path {
        let centerX = rect.midX
        let halfNotchWidth = notchRadius * notchHorizontalScale
        let shoulderLength: CGFloat = 10
        let shoulderDrop: CGFloat = 6
        let leftStart = centerX - halfNotchWidth
        let rightStart = centerX + halfNotchWidth
        let leftShoulderStart = leftStart - shoulderLength
        let rightShoulderEnd = rightStart + shoulderLength
        let ellipseControl = 0.552_284_75
        let verticalControl = notchRadius * ellipseControl
        let horizontalControl = halfNotchWidth * ellipseControl

        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        path.addLine(to: CGPoint(x: leftShoulderStart, y: 0))
        path.addCurve(
            to: CGPoint(x: leftStart, y: shoulderDrop),
            control1: CGPoint(x: leftShoulderStart + shoulderLength * 0.45, y: 0),
            control2: CGPoint(x: leftStart - shoulderLength * 0.3, y: shoulderDrop)
        )
        path.addCurve(
            to: CGPoint(x: centerX, y: notchRadius),
            control1: CGPoint(x: leftStart, y: max(verticalControl - shoulderDrop, shoulderDrop)),
            control2: CGPoint(x: centerX - horizontalControl, y: notchRadius)
        )
        path.addCurve(
            to: CGPoint(x: rightStart, y: shoulderDrop),
            control1: CGPoint(x: centerX + horizontalControl, y: notchRadius),
            control2: CGPoint(x: rightStart, y: max(verticalControl - shoulderDrop, shoulderDrop))
        )
        path.addCurve(
            to: CGPoint(x: rightShoulderEnd, y: 0),
            control1: CGPoint(x: rightStart + shoulderLength * 0.3, y: shoulderDrop),
            control2: CGPoint(x: rightShoulderEnd - shoulderLength * 0.45, y: 0)
        )

        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: cornerRadius),
            control: CGPoint(x: rect.maxX, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}
