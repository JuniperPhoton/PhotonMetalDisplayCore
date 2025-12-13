//
//  ContentView.swift
//  Demo
//
//  Created by JuniperPhoton on 2024/11/21.
//

import SwiftUI
import PhotonMetalDisplayCore

@Observable
class ViewModel {
    private var imageToDisplay: CIImage?
    
    let renderer = MetalRenderer()
    
    var showHDR = false
    
    init() {
        renderer.initializeCIContext(colorSpace: nil, name: "my_renderer")
        renderer.setDebugMode(true)
    }
    
    @MainActor
    func loadBuiltInImage() async {
        let image = await loadImageInternal()
        self.imageToDisplay = image
        renderer.requestChanged(displayedImage: image)
    }
    
    private func loadImageInternal() async -> CIImage? {
        guard let url = Bundle.main.url(forResource: "test", withExtension: "jpg") else {
            return nil
        }
        
        guard let inputImage = CIImage(contentsOf: url) else {
            return nil
        }
        
        if showHDR, let gainMap = CIImage(contentsOf: url, options: [.auxiliaryHDRGainMap: true, .applyOrientationProperty: true]) {
            return inputImage.applyingGainMap(gainMap)
        } else {
            return inputImage
        }
    }
}

struct ContentView: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                MetalView(
                    renderer: viewModel.renderer,
                    renderMode: .renderWhenDirty,
                    isOpaque: false,
                    prefersDynamicRange: viewModel.showHDR ? .hdr : .sdr,
                    startMonitorTask: true
                )
            }.toolbar {
                Toggle("Show HDR", isOn: $viewModel.showHDR)
            }.task(id: viewModel.showHDR) {
                await viewModel.loadBuiltInImage()
            }
        }
    }
}

#Preview {
    ContentView()
}
