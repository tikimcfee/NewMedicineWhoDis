//
//  RadialButtons.swift
//  Drugs!
//
//  Created by Ivan Lugo on 7/27/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

struct CircleInputView: View {
    var body: some View {
        VStack(spacing: 20) {
            Circle() // dynamically sized circle
                .stroke()
                .frame(width: 200, height: 200)
                .overlay(GeometryReader{ geometry in
                    let radius = geometry.size.width / 2.0
                    let translated = CGPoint(x: radius, y: radius)
                    DialBuilder.makeDial(dialSize: 48.0, translated: translated, radius: radius)
                })
        }
    }
}

struct DialBuilder {
    struct CircleButton: Identifiable {
        var id: Int { number }
        let number: Int
        let position: CGPoint
    }
    
    static func makeDial(
        dialSize: CGFloat,
        translated: CGPoint,
        radius: CGFloat
    ) -> some View {
        let buttons = makeRadialButtons(
            center: translated,
            radius: radius,
            numberOfPoints: (0...12)
        )
        
        return ForEach(buttons, id: \.id) { solution in
            Circle()
                .overlay(
                    Text("\(solution.number)")
                        .foregroundColor(.white)
                )
                .position(x: solution.position.x, y: solution.position.y)
                .frame(width: dialSize, height: dialSize)
            
        }
    }
    
    static func makeRadialButtons(
        center: CGPoint,
        radius: CGFloat,
        numberOfPoints: ClosedRange<Int>
    ) -> [CircleButton] {
        let count = CGFloat(numberOfPoints.count)
        let twopi = 2.0 * CGFloat.pi
        //    let rotation = CGFloat.pi / 2.0
        let rotation = CGFloat(0.0)
        let verticalCompression = CGFloat(1.0)
        let horizontalCompression = CGFloat(1.0)
        
        return numberOfPoints.map { xPos in
            let nthItem = CGFloat(xPos)
            let x = center.x + radius * horizontalCompression * cos(twopi * nthItem / count - rotation)
            let y = center.y + radius * verticalCompression * sin(twopi * nthItem / count - rotation)
            return CircleButton(number: xPos + 1, position: CGPoint(x: x, y: y))
        }
    }
}
