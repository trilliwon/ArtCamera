//
//  FilterRenderers.swift
//  Camera
//
//  Created by WON on 10/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import CoreImage
import CoreMedia
import CoreVideo

let filters = [Filter(name: "Nashville", applier: Filter.nashvilleFilter),
               Filter(name: "Toaster", applier: Filter.toasterFilter),
               Filter(name: "1977", applier: Filter.apply1977Filter),
               Filter(name: "Clarendon", applier: Filter.clarendonFilter),
               Filter(name: "Chrome", coreImageFilterName: "CIPhotoEffectChrome"),
               Filter(name: "Fade", coreImageFilterName: "CIPhotoEffectFade"),
               Filter(name: "Instant", coreImageFilterName: "CIPhotoEffectInstant"),
               Filter(name: "Mono", coreImageFilterName: "CIPhotoEffectMono"),
               Filter(name: "Noir", coreImageFilterName: "CIPhotoEffectNoir"),
               Filter(name: "Process", coreImageFilterName: "CIPhotoEffectProcess"),
               Filter(name: "Tonal", coreImageFilterName: "CIPhotoEffectTonal"),
               Filter(name: "Transfer", coreImageFilterName: "CIPhotoEffectTransfer"),
               Filter(name: "Tone", coreImageFilterName: "CILinearToSRGBToneCurve"),
               Filter(name: "Linear", coreImageFilterName: "CISRGBToneCurveToLinear"),
               Filter(name: "Sepia", coreImageFilterName: "CISepiaTone")]

let renderers = filters.map { FilterRenderer(name: $0.name, filter: $0.applier!) }

class FilterRenderer: FilterRenderable {

    var filter: FilterApplier
    var description: String
    var isPrepared: Bool = false

    var nashvilleFilter: CIFilter?

    private var ciContext: CIContext?
    private var outputColorSpace: CGColorSpace?
    private var outputPixelBufferPool: CVPixelBufferPool?

    private(set) var outputFormatDescription: CMFormatDescription?
    private(set) var inputFormatDescription: CMFormatDescription?

    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()

        (outputPixelBufferPool,
         outputColorSpace,
         outputFormatDescription) = allocateOutputBufferPool(with: formatDescription,
                                                             outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        if let device = MTLCreateSystemDefaultDevice() {
            ciContext = CIContext(mtlDevice: device)
        } else {
            ciContext = CIContext()
        }

        isPrepared = true
    }

    func reset() {
        ciContext = nil
        nashvilleFilter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }

    init(name: String, filter: @escaping FilterApplier) {
        self.description = name
        self.filter = filter
    }

    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let filteredImage = filter(sourceImage) else {
            print("CIFilter failed to render image")
            return nil
        }

        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }

        // Render the filtered image out to a pixel buffer (no locking needed
        // , as CIContext's render method will do that)
        ciContext?.render(filteredImage,
                          to: outputPixelBuffer,
                          bounds: filteredImage.extent,
                          colorSpace: outputColorSpace)
        return outputPixelBuffer
    }
}
