attribute vec3 in_Position;
attribute vec3 in_Normal;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
attribute vec4 in_Colour2; //Joint Indexes
attribute vec4 in_Colour3; //Joint Weights

varying vec3 v_vPosition;
varying vec3 v_vNormal;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    //Bit weird, but we have to do this so the compiler doesn't strip out reference to attributes that we're not using
    //I'm sure there's a directive/pragma we can use to stop this, but I cba to research that right now (and GM/ANGLE might not even support it)
    vec4 _0 = in_Colour;
    vec4 _1 = in_Colour2;
    vec4 _2 = in_Colour3;
    
    vec4 wsPos = gm_Matrices[MATRIX_WORLD]*vec4(in_Position, 1.0);
    gl_Position = gm_Matrices[MATRIX_PROJECTION]*gm_Matrices[MATRIX_VIEW]*wsPos;
    
    v_vPosition = wsPos.xyz;
    v_vNormal   = (gm_Matrices[MATRIX_WORLD]*vec4(in_Normal, 0.0)).xyz;
    v_vColour   = in_Colour;
    v_vTexcoord = in_TextureCoord;
}
