/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Rosy colored filter renderer implemented with Core Image.
*/

import CoreImage
import CoreMedia
import CoreVideo

class RosyRenderer: FilterRenderable {

    var filter: FilterApplier
	var description: String
	var isPrepared = false

	private var ciContext: CIContext?
	private var rosyFilter: CIFilter?
	private var outputColorSpace: CGColorSpace?
	private var outputPixelBufferPool: CVPixelBufferPool?
	private(set) var outputFormatDescription: CMFormatDescription?
	private(set) var inputFormatDescription: CMFormatDescription?

    init(name: String, filter: @escaping FilterApplier) {
        self.description = name
        self.filter = filter
    }

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

		ciContext = CIContext()
		rosyFilter = CIFilter(name: "CIColorMatrix")
		rosyFilter!.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")

		isPrepared = true
	}

	func reset() {
		ciContext = nil
		rosyFilter = nil
		outputColorSpace = nil
		outputPixelBufferPool = nil
		outputFormatDescription = nil
		inputFormatDescription = nil
		isPrepared = false
	}

	func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
		guard let rosyFilter = rosyFilter,
			  let ciContext = ciContext,
			isPrepared else {
			assertionFailure("Invalid state: Not prepared")
			return nil
		}

		let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
		rosyFilter.setValue(sourceImage, forKey: kCIInputImageKey)

		guard let filteredImage = rosyFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
			print("CIFilter failed to render image")
			return nil
		}

		var pbuf: CVPixelBuffer?
		CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
		guard let outputPixelBuffer = pbuf else {
			print("Allocation failure")
			return nil
		}

		// Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
		ciContext.render(filteredImage, to: outputPixelBuffer, bounds: filteredImage.extent, colorSpace: outputColorSpace)
		return outputPixelBuffer
	}
}
