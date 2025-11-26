shader_type canvas_item;

uniform bool filled = true;
uniform float thickness : hint_range(0.0, 0.5) = 0.05;
uniform float smoothness : hint_range(0.0, 0.1) = 0.01;

void fragment() {
    // Get the UV coordinates centered at (0.5, 0.5)
    vec2 uv = UV - vec2(0.5);
    
    // Calculate distance from center
    float dist = length(uv);
    
    // Circle radius (0.5 fills the entire rect)
    float radius = 0.5;
    
    float alpha;
    
    if (filled) {
        // Filled circle: alpha is 1 inside, 0 outside
        alpha = 1.0 - smoothstep(radius - smoothness, radius, dist);
    } else {
        // Unfilled circle: alpha is 1 in the ring, 0 elsewhere
        float outer = radius;
        float inner = radius - thickness;
        
        // Create ring by subtracting inner circle from outer
        float outer_mask = 1.0 - smoothstep(outer - smoothness, outer, dist);
        float inner_mask = smoothstep(inner, inner + smoothness, dist);
        
        alpha = outer_mask * inner_mask;
    }
    
    // Use the ColorRect's modulate color and apply our calculated alpha
    COLOR = vec4(COLOR.rgb, COLOR.a * alpha);
}