#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

NSWindow *window = nil;
id<MTLDevice> device = nil;
id<MTLCommandQueue> commandQueue = nil;
CAMetalLayer *metalLayer = nil;
id<MTLTexture> currentTexture = nil;

void psx_init_window(int width, int height)
{
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSRect frame = NSMakeRect(0, 0, width, height);
    window = [[NSWindow alloc] initWithContentRect:frame
                                         styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable)
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    [window setTitle:@"PSXADA Emulator - Metal Renderer"];
    [window makeKeyAndOrderFront:nil];

    device = MTLCreateSystemDefaultDevice();
    commandQueue = [device newCommandQueue];

    metalLayer = [CAMetalLayer layer];
    metalLayer.device = device;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.frame = frame;

    window.contentView.layer = metalLayer;
    window.contentView.wantsLayer = YES;

    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:NO];
    currentTexture = [device newTextureWithDescriptor:desc];
}

void psx_update_frame(const void *buffer_address, int size)
{
    if (!metalLayer || !currentTexture)
        return;

    MTLRegion region = MTLRegionMake2D(0, 0, currentTexture.width, currentTexture.height);
    [currentTexture replaceRegion:region mipmapLevel:0 withBytes:buffer_address bytesPerRow:currentTexture.width * 4];

    id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
    if (!drawable)
        return;

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    [blitEncoder copyFromTexture:currentTexture
                     sourceSlice:0
                     sourceLevel:0
                    sourceOrigin:MTLOriginMake(0, 0, 0)
                      sourceSize:MTLSizeMake(currentTexture.width, currentTexture.height, 1)
                       toTexture:drawable.texture
                destinationSlice:0
                destinationLevel:0
               destinationOrigin:MTLOriginMake(0, 0, 0)];
    [blitEncoder endEncoding];

    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

int psx_process_events()
{
    int is_visible = 0;
    @autoreleasepool
    {
        NSEvent *event;
        while ((event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                           untilDate:[NSDate distantPast]
                                              inMode:NSDefaultRunLoopMode
                                             dequeue:YES]))
        {
            [NSApp sendEvent:event];
        }
        if (window != nil)
        {
            is_visible = [window isVisible] ? 1 : 0;
        }
    }
    return is_visible;
}
