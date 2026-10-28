varying vec2 v_vTexcoord;
varying vec4 v_vColour;
void main() {
    vec4 source = texture2D(gm_BaseTexture, v_vTexcoord);
    float brightest = max(source.r, max(source.g, source.b));
    float darkest = min(source.r, min(source.g, source.b));
    // Replace the original hue, retaining brightness and pale highlights.
    // Vertex RGB supplies the target colour instead of multiplying the blue art.
    vec3 recoloured = darkest * vec3(1.0) + (brightest - darkest) * v_vColour.rgb;
    gl_FragColor = vec4(recoloured, source.a * v_vColour.a);
}
