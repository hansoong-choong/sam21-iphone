//
//  ImageView.swift
//  SAM2-Demo
//
//  Created by Cyril Zakka on 9/8/24.
//

import SwiftUI

struct ImageView: View {
    let image: NSImage
    @Binding var currentScale: CGFloat
    @Binding var selectedTool: SAMTool?
    @Binding var selectedCategory: SAMCategory?
    @Binding var selectedPoints: [SAMPoint]
    @Binding var boundingBoxes: [SAMBox]
    @Binding var currentBox: SAMBox?
    @Binding var segmentationImages: [SAMSegmentation]
    @Binding var currentSegmentation: SAMSegmentation?
    @Binding var imageSize: CGSize
    @Binding var originalSize: CGSize?
    
    @State var animationPoint: CGPoint = .zero
    @ObservedObject var sam2: SAM2
    @State private var error: Error?
    
    var pointSequence: [SAMPoint] {
        boundingBoxes.flatMap { $0.points } + selectedPoints
    }

    var body: some View {
#if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(currentScale)
            .onTapGesture(coordinateSpace: .local) { handleTap(at: $0) }
            .gesture(boundingBoxGesture)
            .background(GeometryReader { geometry in
                Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { imageSize = $0 }
            .onChange(of: selectedPoints.count, {
                if !selectedPoints.isEmpty {
                    performForwardPass()
                }
            })
            .onChange(of: boundingBoxes.count, {
                if !boundingBoxes.isEmpty {
                    performForwardPass()
                }
            })
            .overlay {
                PointsOverlay(selectedPoints: $selectedPoints, selectedTool: $selectedTool, imageSize: imageSize)
                BoundingBoxesOverlay(boundingBoxes: boundingBoxes, currentBox: currentBox, imageSize: imageSize)

                if !segmentationImages.isEmpty {
                    ForEach(Array(segmentationImages.enumerated()), id: \.element.id) { index, segmentation in
                        SegmentationOverlay(segmentationImage: $segmentationImages[index], imageSize: imageSize, shouldAnimate: false)
                            .zIndex(Double (segmentationImages.count - index))
                    }
                }
               
                if let currentSegmentation = currentSegmentation {
                    SegmentationOverlay(segmentationImage: .constant(currentSegmentation), imageSize: imageSize, origin: animationPoint, shouldAnimate: true)
                        .zIndex(Double(segmentationImages.count + 1))
                }
            }
        #else
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(currentScale)
                .onTapGesture(coordinateSpace: .local) { handleTap(at: $0) }
                .gesture(boundingBoxGesture)
                .onHover { changeCursorAppearance(is: $0) }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
                })
                .onPreferenceChange(SizePreferenceKey.self) { imageSize = $0 }
                .onChange(of: selectedPoints.count, {
                    if !selectedPoints.isEmpty {
                        performForwardPass()
                    }
                })
                .onChange(of: boundingBoxes.count, {
                    if !boundingBoxes.isEmpty {
                        performForwardPass()
                    }
                })
                .overlay {
                    PointsOverlay(selectedPoints: $selectedPoints, selectedTool: $selectedTool, imageSize: imageSize)
                    BoundingBoxesOverlay(boundingBoxes: boundingBoxes, currentBox: currentBox, imageSize: imageSize)

                    if !segmentationImages.isEmpty {
                        ForEach(Array(segmentationImages.enumerated()), id: \.element.id) { index, segmentation in
                            SegmentationOverlay(segmentationImage: $segmentationImages[index], imageSize: imageSize, shouldAnimate: false)
                                .zIndex(Double (segmentationImages.count - index))
                        }
                    }
                   
                    if let currentSegmentation = currentSegmentation {
                        SegmentationOverlay(segmentationImage: .constant(currentSegmentation), imageSize: imageSize, origin: animationPoint, shouldAnimate: true)
                            .zIndex(Double(segmentationImages.count + 1))
                    }
                }
        #endif
        
    }

#if !canImport(UIKit)
    private func changeCursorAppearance(is inside: Bool) {
        if inside {
            if selectedTool == pointTool {
                NSCursor.pointingHand.push()
            } else if selectedTool == boundingBoxTool {
                NSCursor.crosshair.push()
            }
        } else {
            NSCursor.pop()
        }
    }
    #endif
    
    private var boundingBoxGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard selectedTool == boundingBoxTool else { return }
                
                if currentBox == nil {
                    currentBox = SAMBox(startPoint: value.startLocation.fromSize(imageSize), endPoint: value.location.fromSize(imageSize), category: selectedCategory!)
                } else {
                    currentBox?.endPoint = value.location.fromSize(imageSize)
                }
            }
            .onEnded { value in
                guard selectedTool == boundingBoxTool else { return }
                
                if let box = currentBox {
                    boundingBoxes.append(box)
                    animationPoint = box.midpoint.toSize(imageSize)
                    currentBox = nil
                }
            }
    }
    
    private func handleTap(at location: CGPoint) {
        if selectedTool == pointTool {
            placePoint(at: location)
            animationPoint = location
        }
    }
    
    private func placePoint(at coordinates: CGPoint) {
        let samPoint = SAMPoint(coordinates: coordinates.fromSize(imageSize), category: selectedCategory!)
        self.selectedPoints.append(samPoint)
    }
    
    private func performForwardPass() {
        Task {
            do {
                try await sam2.getPromptEncoding(from: pointSequence, with: imageSize)
                if let mask = try await sam2.getMask(for: originalSize ?? .zero) {
                    DispatchQueue.main.async {
                        let colorSet = self.segmentationImages.map { $0.tintColor }
                        let furthestColor = furthestColor(from: colorSet, among: SAMSegmentation.candidateColors)
                        let segmentationNumber = segmentationImages.count
                        let segmentationOverlay = SAMSegmentation(image: mask, tintColor: furthestColor, title: "Untitled \(segmentationNumber + 1)")
                        self.currentSegmentation = segmentationOverlay
                    }
                }
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    ContentView()
}

extension CGPoint {
    func fromSize(_ size: CGSize) -> CGPoint {
        CGPoint(x: x / size.width, y: y / size.height)
    }

    func toSize(_ size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}
