// Based on <https://cindori.com/developer/swiftui-shaders-marquee>

#include <metal_stdlib>
using namespace metal;

[[stitchable]] float2 marquee(float2 position, float time, float speed, float widthAndSpacing) {
    return float2(fmod(position.x + (time * (speed * 100.0)), widthAndSpacing), position.y);
}
