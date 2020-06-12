/// Loads a .dae (Collada) file from disk and turns it into a vertex buffer
/// @jujuadams
/// 
/// This isn't a full implementation of the .dae format, but it's a starting point at least
/// 
/// This script expects the vertex format to be setup as follows:
/// - 3D Position
/// - Normal
/// - Colour
/// - Texture Coordinate
/// If your preferred vertex format does not have normals or texture coordinates,
/// use the "writeNormals" and/or "writeTexcoords" to toggle writing that data.
/// 
/// Texture coordinates for a .dae model will typically be normalised and in the
/// range (0,0) -> (1,1). Please use another script to remap texture coordinates
/// to GameMaker's atlased UV space.
/// 
/// @param filename        File to read from
/// @param vertexFormat    Vertex format to use. See above for details on what vertex formats are supported
/// @param flipUVs         Whether to flip the y-axis (V-component) of the texture coordinates. This is useful to correct for DirectX / OpenGL idiosyncrasies
/// @param reverseTris     Whether to reverse the triangle definition order to be compatible with the culling mode of your choice (clockwise/counter-clockwise)

var _filename          = argument0;
var _vformat           = argument1;
var _flip_texcoords    = argument2;
var _reverse_triangles = argument3;

var _buffer = buffer_load(_filename);
var _result = dotdae_model_load(_buffer, _vformat, _flip_texcoords, _reverse_triangles);
buffer_delete(_buffer);

return _result;