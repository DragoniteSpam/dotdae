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
/// 
/// Texture coordinates for a .dae model will typically be normalised and in the
/// range (0,0) -> (1,1). Please use another script to remap texture coordinates
/// to GameMaker's atlased UV space.
/// 
/// @param filename       File to read from
/// @param vertexFormat   Vertex format to use. See above for details on what vertex formats are supported
/// @param flipUVs        Whether to flip the y-axis (V-component) of the texture coordinates. This is useful to correct for DirectX / OpenGL idiosyncrasies
/// @param reverseTris    Whether to reverse the triangle definition order to be compatible with the culling mode of your choice (clockwise/counter-clockwise)

if (DOTDAE_OUTPUT_LOAD_TIME) var _timer = get_timer();

var _buffer            = argument0;
var _vformat           = argument1;
var _flip_texcoords    = argument2;
var _reverse_triangles = argument3;

var _dae_object_map         = ds_map_create();
var _dae_effects_list       = ds_list_create();
var _dae_materials_list     = ds_list_create();
var _dae_images_list        = ds_list_create();
var _dae_geometries_list    = ds_list_create();
var _dae_visual_scenes_list = ds_list_create();

global.__dae_vertex_format      = _vformat;
global.__dae_flip_texcoords     = _flip_texcoords;
global.__dae_reverse_triangles  = _reverse_triangles;
global.__dae_object_map         = _dae_object_map;
global.__dae_object_stack       = ds_list_create();
global.__dae_effects_list       = _dae_effects_list;
global.__dae_materials_list     = _dae_materials_list;
global.__dae_images_list        = _dae_images_list;
global.__dae_geometries_list    = _dae_geometries_list;
global.__dae_visual_scenes_list = _dae_visual_scenes_list;

//Parse the .dae XML found in the buffer
var _xml = dotdae_xml_buffer_decode(_buffer, 0, buffer_get_size(_buffer));
dotdae_ds_parse(_xml, undefined);
ds_map_destroy(_xml);

//If we want to report the load time, do it!
if (DOTDAE_OUTPUT_LOAD_TIME) show_debug_message("dotdae_load(): Time to load was " + string((get_timer() - _timer)/1000) + "ms");

//Return our data
//return _model_array;