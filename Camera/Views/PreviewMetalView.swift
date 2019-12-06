//
//  AppDelegate.swift
//  Recoger
//
//  Created by Won on 07/05/2017.
//  Copyright © 2017 Won. All rights reserved.
//

import AVFoundation
import CoreMedia
import Metal
import MetalKit

#if targetEnvironment(simulator)
final class PreviewMetalView: UIView {

    static var imageNameList: [String] {
        return ["shifaaz-shamoon.jpg", "roman-bozhko.jpg", "jon-tyson.jpg", "natasha-kapur.jpg", "luca-bravo.jpg", "casey-horner.jpg"]
    }

    var image = UIImageView(image: UIImage(named: imageNameList[5])!)

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(image, at: 0)
        image.topAnchor.constraint(equalTo: topAnchor).isActive = true
        image.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        image.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        image.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }

    var mirroring = false
    var pixelBuffer: CVPixelBuffer?

    func showGridView() { }

    func hideGridView() { }
}
#else
final class PreviewMetalView: MTKView, GridDrawable {

    var gridView: GridView?

    var mirroring = false {
        didSet {
            syncQueue.sync {
                internalMirroring = mirroring
            }
        }
    }

    private var internalMirroring: Bool = false

    var pixelBuffer: CVPixelBuffer? {
        didSet {
            syncQueue.sync {
                internalPixelBuffer = pixelBuffer
            }
        }
    }

    private var internalPixelBuffer: CVPixelBuffer?

    private let syncQueue = DispatchQueue(label: "Preview View Sync Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    private var textureWidth: Int = 0
    private var textureHeight: Int = 0
    private var textureMirroring = false

    private var commandQueue: MTLCommandQueue?

    private var textureCache: CVMetalTextureCache?
    private var sampler: MTLSamplerState!
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexCoordBuffer: MTLBuffer!
    private var textCoordBuffer: MTLBuffer!

    private func setupTransform(width: Int, height: Int, mirroring: Bool) {

        textureWidth = width
        textureHeight = height
        textureMirroring = mirroring

        let bounds = UIScreen.main.bounds
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0

        scaleX = Float(bounds.width / CGFloat(textureHeight))
        scaleY = Float(bounds.height / CGFloat(textureWidth))

        if scaleX > scaleY {
            scaleY = scaleX / scaleY
            scaleX = 1.0
        } else {
            scaleX = scaleY / scaleX
            scaleY = 1.0
        }

        if textureMirroring {
            scaleX *= -1.0
        }

        // Vertex coordinate takes the gravity into account.
        let vertexData: [Float] = [
            -scaleX, -scaleY, 0.0, 1.0,
            scaleX, -scaleY, 0.0, 1.0,
            -scaleX, scaleY, 0.0, 1.0,
            scaleX, scaleY, 0.0, 1.0
        ]
        vertexCoordBuffer = device!.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])

        // Texture coordinate takes the rotation into account.
        let textData: [Float] =  [
            1.0, 1.0,
            1.0, 0.0,
            0.0, 1.0,
            0.0, 0.0
        ]

        textCoordBuffer = device?.makeBuffer(bytes: textData, length: textData.count * MemoryLayout<Float>.size, options: [])
    }

    init() {
        super.init(frame: .zero, device: nil)
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let gridView = GridView()
        addSubview(gridView)
        bringSubviewToFront(gridView)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        gridView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        gridView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gridView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        self.gridView = gridView
        showGridView()
        device = MTLCreateSystemDefaultDevice()

        configureMetal()

        createTextureCache()

        colorPixelFormat = .bgra8Unorm
    }

    func configureMetal() {
        let defaultLibrary = device!.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")

        // To determine how textures are sampled, create a sampler descriptor to query for a sampler state from the device.
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        sampler = device!.makeSamplerState(descriptor: samplerDescriptor)

        do {
            renderPipelineState = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create preview Metal view pipeline state. (\(error))")
        }

        commandQueue = device!.makeCommandQueue()
    }

    func createTextureCache() {
        var newTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        } else {
            assertionFailure("Unable to allocate texture cache")
        }
    }

    /// - Tag: DrawMetalTexture
    override func draw(_ rect: CGRect) {
        var pixelBuffer: CVPixelBuffer?
        var mirroring = false

        syncQueue.sync {
            pixelBuffer = internalPixelBuffer
            mirroring = internalMirroring
        }

        guard let drawable = currentDrawable,
            let currentRenderPassDescriptor = currentRenderPassDescriptor,
            let previewPixelBuffer = pixelBuffer else {
                return
        }

        // Create a Metal texture from the image buffer.
        let width = CVPixelBufferGetWidth(previewPixelBuffer)
        let height = CVPixelBufferGetHeight(previewPixelBuffer)

        if textureCache == nil {
            createTextureCache()
        }
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache!,
                                                  previewPixelBuffer,
                                                  nil,
                                                  .bgra8Unorm,
                                                  width,
                                                  height,
                                                  0,
                                                  &cvTextureOut)
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create preview texture")

            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        if texture.width != textureWidth ||
            texture.height != textureHeight ||
            mirroring != textureMirroring {
            setupTransform(width: texture.width, height: texture.height, mirroring: mirroring)
        }

        // Set up command buffer and encoder
        guard let commandQueue = commandQueue else {
            print("Failed to create Metal command queue")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Failed to create Metal command buffer")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor) else {
            print("Failed to create Metal command encoder")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        commandEncoder.label = "Preview display"
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        // Draw to the screen.
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
#endif
