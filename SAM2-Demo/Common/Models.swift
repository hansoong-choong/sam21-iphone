//
//  Models.swift
//  SAM2-Demo
//
//  Created by Cyril Zakka on 8/19/24.
//

import Foundation
import SwiftUI

enum SAMCategoryType: Int {
    case background = 0
    case foreground = 1
    case boxOrigin = 2
    case boxEnd = 3

    var description: String {
        switch self {
        case .foreground:
            return "Foreground"
        case .background:
            return "Background"
        case .boxOrigin:
            return "Box Origin"
        case .boxEnd:
            return "Box End"
        }
    }
}

struct SAMCategory: Hashable {
    let id: UUID = UUID()
    let type: SAMCategoryType
    let name: String
    let iconName: String
    let color: Color

    var typeDescription: String {
        type.description
    }

    static let foreground = SAMCategory(
        type: .foreground,
        name: "Foreground",
        iconName: "square.on.square.dashed",
        color: .pink
    )

    static let background = SAMCategory(
        type: .background,
        name: "Background",
        iconName: "square.on.square.intersection.dashed",
        color: .purple
    )

    static let boxOrigin = SAMCategory(
        type: .boxOrigin,
        name: "Box Origin",
        iconName: "",
        color: .white
    )

    static let boxEnd = SAMCategory(
        type: .boxEnd,
        name: "Box End",
        iconName: "",
        color: .white
    )
}


struct SAMPoint: Hashable, Identifiable {
    let id = UUID()
    let coordinates: CGPoint
    let category: SAMCategory
    let dateAdded = Date()
}

struct SAMBox: Hashable, Identifiable {
    let id = UUID()
    var startPoint: CGPoint
    var endPoint: CGPoint
    let category: SAMCategory
    let dateAdded = Date()
    var midpoint: CGPoint {
        return CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        )
    }
}

extension SAMBox {
    var points: [SAMPoint] {
        [SAMPoint(coordinates: startPoint, category: .boxOrigin), SAMPoint(coordinates: endPoint, category: .boxEnd)]
    }
}

struct SAMSegmentation: Hashable, Identifiable {
    let id = UUID()
    var image: CIImage
    var tintColor: Color {
        didSet {
            updateTintedImage()
        }
    }
    var title: String = ""
    var firstAppearance: Int?
    var isHidden: Bool = false
    
    private var tintedImage: CIImage?

    static let defaultColor: Color = Color(.sRGB, red: 30/255, green: 144/255, blue: 1)
    static let candidateColors: [Color] = [
        defaultColor,
        Color.red,
        Color.green,
        Color.brown,
        Color.indigo,
        Color.cyan,
        Color.yellow,
        Color.purple,
        Color.orange,
        Color.teal,
        Color.indigo,
        Color.mint,
        Color.pink,
    ]

    init(image: CIImage, tintColor: Color = Color(.sRGB, red: 30/255, green: 144/255, blue: 1), title: String = "", firstAppearance: Int? = nil, isHidden: Bool = false) {
        self.image = image
        self.tintColor = tintColor
        self.title = title
        self.firstAppearance = firstAppearance
        self.isHidden = isHidden
        updateTintedImage()
    }

#if canImport(UIKit)
    typealias NSColor = UIColor
    #endif
    private mutating func updateTintedImage() {
        let ciColor = CIColor(color: NSColor(tintColor))
        let monochromeFilter = CIFilter.colorMonochrome()
        monochromeFilter.inputImage = image
#if canImport(UIKit)
        monochromeFilter.color = ciColor
        #else
        monochromeFilter.color = ciColor!
        #endif
        monochromeFilter.intensity = 1.0
        tintedImage = monochromeFilter.outputImage
    }
    
    static func randomCandidateColor() -> Color? {
        Self.candidateColors.randomElement()
    }

    var cgImage: CGImage {
        let context = CIContext()
        return context.createCGImage(tintedImage ?? image, from: (tintedImage ?? image).extent)!
    }
}

struct SAMTool: Hashable {
    let id: UUID = UUID()
    let name: String
    let iconName: String
}

// Tools
let pointTool: SAMTool = SAMTool(name: "Point", iconName: "hand.point.up.left")
let boundingBoxTool: SAMTool = SAMTool(name: "Bounding Box", iconName: "rectangle.dashed")
