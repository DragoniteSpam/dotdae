varying vec3 v_vPosition;
varying vec3 v_vNormal;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    float dotFactor = max(0.0, dot(normalize(v_vNormal), normalize(vec3(-1.0, -0.8, 0.6))));
    vec4 colour = vec4(mix(vec3(0.3), v_vColour.rgb, dotFactor), 1.0);
    
    gl_FragColor = colour*texture2D( gm_BaseTexture, v_vTexcoord );
}