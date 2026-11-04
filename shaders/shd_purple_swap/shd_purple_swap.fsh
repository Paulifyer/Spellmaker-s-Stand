varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 col = texture2D(gm_BaseTexture, v_vTexcoord);

    // Example check for a blue-ish pixel (adjust thresholds as needed)
    if (col.b > 0.5 && col.r < 0.3) {
        col.r = 0.6; // Add red to shift blue toward purple/magenta
        col.g = 0.0; // Reduce green
        col.b = 0.9; // Keep/adjust blue
    }

    gl_FragColor = v_vColour * col;
}