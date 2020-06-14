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

enum eDotDae
{
    ObjectMap,
    EffectList,
    MaterialList,
    ImageList,
    GeometryList,
    VertexBufferList,
    __Size
}

var _dae_object_map          = ds_map_create();
var _dae_effects_list        = ds_list_create();
var _dae_materials_list      = ds_list_create();
var _dae_images_list         = ds_list_create();
var _dae_geometries_list     = ds_list_create();
var _dae_vertex_buffers_list = ds_list_create();

var _container = array_create(eDotDae.__Size, undefined);
_container[@ eDotDae.ObjectMap       ] = _dae_object_map;
_container[@ eDotDae.EffectList      ] = _dae_effects_list;
_container[@ eDotDae.MaterialList    ] = _dae_materials_list;
_container[@ eDotDae.ImageList       ] = _dae_images_list;
_container[@ eDotDae.GeometryList    ] = _dae_geometries_list;
_container[@ eDotDae.VertexBufferList] = _dae_vertex_buffers_list;

global.__dae_object_stack        = ds_list_create();
global.__dae_object_map          = _dae_object_map;
global.__dae_effects_list        = _dae_effects_list;
global.__dae_materials_list      = _dae_materials_list;
global.__dae_images_list         = _dae_images_list;
global.__dae_geometries_list     = _dae_geometries_list;
global.__dae_vertex_buffers_list = _dae_vertex_buffers_list;

//Parse the .dae XML found in the buffer
if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Parsing XML... (This may take some time)");
var _xml = dotdae_xml_buffer_decode(_buffer, 0, buffer_get_size(_buffer));
if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("...finished parsing XML");

//Traverse the generated XML and build a data structure we can use
if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Traversing data structure...");
__dotdae_model_load_inner(_xml, undefined);
if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("...finished traversing data structure");

//Clean up the XML data
ds_map_destroy(_xml);

#region Pre-process effect -> texture so we need less code in dotdae_model_draw()

if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Pre-processing effect -> texture links");
var _e = 0;
repeat(ds_list_size(_dae_effects_list))
{
    var _effect = _dae_effects_list[| _e];
    __dotdae_resolve_effect_texture(_dae_object_map, _effect, eDotDaeEffect.EmissionImageName , eDotDaeEffect.EmissionTexture );
    __dotdae_resolve_effect_texture(_dae_object_map, _effect, eDotDaeEffect.AmbientImageName  , eDotDaeEffect.AmbientTexture  );
    __dotdae_resolve_effect_texture(_dae_object_map, _effect, eDotDaeEffect.DiffuseImageName  , eDotDaeEffect.DiffuseTexture  );
    __dotdae_resolve_effect_texture(_dae_object_map, _effect, eDotDaeEffect.SpecularImageName , eDotDaeEffect.SpecularTexture );
    __dotdae_resolve_effect_texture(_dae_object_map, _effect, eDotDaeEffect.ShininessImageName, eDotDaeEffect.ShininessTexture);
    ++_e;
}

#endregion

#region Pre-process vertex buffer -> effect links so we need less code in dotdae_model_draw()

if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Pre-processing vertex buffer -> effect links");
var _v = 0;
repeat(ds_list_size(_dae_vertex_buffers_list))
{
    //Grab our object definition from our list of vertex buffers
    var _object = _dae_vertex_buffers_list[| _v];
    
    //Get our material data
    var _material_name = _object[eDotDaeVertexBuffer.Material];
    var _material = _dae_object_map[? _material_name];
    
    //Set the vertex buffer's effect to the material's effect
    _object[@ eDotDaeVertexBuffer.Effect] = _material[eDotDaeMaterial.InstanceOf];
    
    ++_v;
}

#endregion

#region Iterate over all the vertex buffers we need to make, and make them!

if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Building vertex buffers...");
var _v = 0;
repeat(ds_list_size(_dae_vertex_buffers_list))
{
    //Grab our object definition from our list of vertex buffers
    var _object = _dae_vertex_buffers_list[| _v];
    
    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Building \"", _object[eDotDaeVertexBuffer.Name], "\" using material \"", _object[eDotDaeVertexBuffer.Material], "\"");
    
    var _pstring     = _object[eDotDaeVertexBuffer.PString   ];
    var _input_array = _object[eDotDaeVertexBuffer.InputArray]; //Get our array that describes the vertex buffer layout
    
    //Break down the string found in the <p> tag into a list of indexes
    var _index_list  = dotdae_string_decompose_list(_pstring);
    var _index_count = ds_list_size(_index_list);
    
    //Figure out how many vertices we have
    //This *should* match the value we found in the file
    //TODO - Check that these two values match up and report an error if not (!)
    var _input_count = array_length_1d(_input_array);
    var _vertex_count = _index_count div _input_count;
    
    //Create some variables...
    var _position_index_list = ds_list_create();
    var _normal_index_list   = ds_list_create();
    var _colour_index_list   = ds_list_create();
    var _texcoord_index_list = ds_list_create();
    var _position_source     = undefined;
    var _normal_source       = undefined;
    var _colour_source       = undefined;
    var _texcoord_source     = undefined;
    
    //Iterate over our layout and reorganise the data so we can handle it more safely
    var _i = 0;
    repeat(_input_count)
    {
        var _input = _input_array[_i];
        
        //Find the *actual* source that we want to read (especially notable for handling the VERTEX -> POSITION weirdness)
        var _source = dotdae_ds_resolve_source(_input[eDotDaeInput.Source]);
        var _source_array = _source[eDotDaeSource.FloatArray];
        
        var _collection_list = undefined;
        switch(_input[eDotDaeInput.Semantic])
        {
            case "VERTEX":
            case "POSITION":
                _collection_list = _position_index_list; //Set our sublist to be the position one
                _position_source = _source_array[eDotDaeFloatArray.List]; //And set the source for position data too
            break;
            
            case "NORMAL":
                _collection_list = _normal_index_list;
                _normal_source   = _source_array[eDotDaeFloatArray.List];
            break;
            
            case "COLOR":
                _collection_list = _colour_index_list;
                _colour_source   = _source_array[eDotDaeFloatArray.List];
            break;
            
            case "TEXCOORD":
                _collection_list = _texcoord_index_list;
                _texcoord_source = _source_array[eDotDaeFloatArray.List];
            break;
            
            default:
                //TODO - Error handling
            break;
        }
        
        if (_collection_list != undefined)
        {
            //Copy across the indexes from the main list to our sublist
            var _j = real(_input[eDotDaeInput.Offset]);
            repeat(_vertex_count)
            {
                ds_list_add(_collection_list, _index_list[| _j]);
                _j += _input_count;
            }
        }
            
        ++_i;
    }
    
    //Check if we have sufficient data in every index list
    var _enough_positions = (ds_list_size(_position_index_list) >= _vertex_count);
    var _enough_normals   = (ds_list_size(_normal_index_list  ) >= _vertex_count);
    var _enough_colours   = (ds_list_size(_colour_index_list  ) >= _vertex_count);
    var _enough_texcoords = (ds_list_size(_texcoord_index_list) >= _vertex_count);
    
    //Figure out a format code from the above booleans
    var _format_code = DOTDAE_FORMAT_P*_enough_positions
                     + DOTDAE_FORMAT_N*_enough_normals
                     + DOTDAE_FORMAT_C*_enough_colours
                     + DOTDAE_FORMAT_T*_enough_texcoords;
    
    //Now create our vertex buffer based on what format code we have
    //This seems like a long way round of doing things, but it ends up being more efficient
    //By checking what format to use *outside* the vertex writing loop we avoid potentially hundreds of thousands of unnecessary if-statements
    var _vbuff = vertex_create_buffer();
    vertex_begin(_vbuff, _vformat);
    
    switch(_format_code)
    {
        case DOTDAE_FORMAT_P + DOTDAE_FORMAT_N + DOTDAE_FORMAT_C + DOTDAE_FORMAT_T:
            #region Position, Normal, Colour, Texcoord
            
            //Write all of our data - position, normal, colour, texcoord
            var _i = 0;
            var _r = 0;
            repeat(_vertex_count)
            {
                //Write the position
                var _j = 3*_position_index_list[| _i];
                vertex_position_3d(_vbuff, _position_source[| _j], _position_source[| _j+1], _position_source[| _j+2]);
                
                //Write the normal
                var _j = 3*_normal_index_list[| _i];
                vertex_normal(_vbuff, _normal_source[| _j], _normal_source[| _j+1], _normal_source[| _j+2]);
                
                //Write the colour
                var _j = 3*_colour_index_list[| _i];
                var _colour = make_colour_rgb(255*_colour_source[| _j], 255*_colour_source[| _j+1], 255*_colour_source[| _j+2]);
                vertex_color(_vbuff, _colour, 1.0);
                
                //Write the UV
                var _j = 2*_texcoord_index_list[| _i];
                if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                {
                    vertex_texcoord(_vbuff, _texcoord_source[| _j], 1.0 - _texcoord_source[| _j+1]);
                }
                else
                {
                    vertex_texcoord(_vbuff, _texcoord_source[| _j], _texcoord_source[| _j+1]);
                }
                
                //Iterate!
                if (_reverse_triangles) //TODO - Move this if-check outside the loop?
                {
                    //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                    if (_r == 1) --_i else _i += 2;
                    ++_r;
                    if (_r >= 3) _r = 0;
                }
                else
                {
                    ++_i;
                }
            }
            
            #endregion
        break;
        
        case DOTDAE_FORMAT_P + DOTDAE_FORMAT_C + DOTDAE_FORMAT_T:
            #region Position, Colour, Texcoord
            
            //Write position, colour, texcoord
            var _i = 0;
            var _r = 0;
            repeat(_vertex_count)
            {
                //Write the position
                var _j = 3*_position_index_list[| _i];
                vertex_position_3d(_vbuff, _position_source[| _j], _position_source[| _j+1], _position_source[| _j+2]);
                
                //Write a default null normal
                vertex_normal(_vbuff, 0, 0, 0);
                
                //Write the colour
                var _j = 3*_colour_index_list[| _i];
                var _colour = make_colour_rgb(255*_colour_source[| _j], 255*_colour_source[| _j+1], 255*_colour_source[| _j+2]);
                vertex_color(_vbuff, _colour, 1.0);
                
                //Write the UV
                var _j = 2*_texcoord_index_list[| _i];
                if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                {
                    vertex_texcoord(_vbuff, _texcoord_source[| _j], 1.0 - _texcoord_source[| _j+1]);
                }
                else
                {
                    vertex_texcoord(_vbuff, _texcoord_source[| _j], _texcoord_source[| _j+1]);
                }
                
                //Iterate!
                if (_reverse_triangles) //TODO - Move this if-check outside the loop?
                {
                    //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                    if (_r == 1) --_i else _i += 2;
                    ++_r;
                    if (_r >= 3) _r = 0;
                }
                else
                {
                    ++_i;
                }
            }
            
            #endregion
        break;
        
        case DOTDAE_FORMAT_P + DOTDAE_FORMAT_N + DOTDAE_FORMAT_T:
            #region Position, Normal, Texcoord
            
            //Write position, normal, texcoord
            var _i = 0;
            var _r = 0;
            repeat(_vertex_count)
            {
                //Write the position
                var _j = 3*_position_index_list[| _i];
                vertex_position_3d(_vbuff, _position_source[| _j], _position_source[| _j+1], _position_source[| _j+2]);
                
                //Write the normal
                var _j = 3*_normal_index_list[| _i];
                vertex_normal(_vbuff, _normal_source[| _j], _normal_source[| _j+1], _normal_source[| _j+2]);
                
                //Write a default colour
                vertex_color(_vbuff, DOTDAE_DEFAULT_DIFFUSE_RGB, 1.0);
                
                //Write the UV
                var _j = 2*_texcoord_index_list[| _i];
                if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                {
                    vertex_texcoord(_vbuff, _texcoord_source[| _j], 1.0 - _texcoord_source[| _j+1]);
                }
                else
                {
                    vertex_texcoord(_vbuff, _texcoord_source[| _j], _texcoord_source[| _j+1]);
                }
                
                //Iterate!
                if (_reverse_triangles) //TODO - Move this if-check outside the loop?
                {
                    //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                    if (_r == 1) --_i else _i += 2;
                    ++_r;
                    if (_r >= 3) _r = 0;
                }
                else
                {
                    ++_i;
                }
            }
            
            #endregion
        break;
        
        default:
            #region Fallback
            
            //If this specific format code isn't supported then write using some slow generic code
            __dotdae_trace("Warning! Using slow vertex writer for format code ", _format_code);
            
            var _i = 0;
            var _r = 0;
            repeat(_vertex_count)
            {
                //Write the position
                var _j = _position_index_list[| _i];
                if (_j != undefined)
                {
                    _j *= 3;
                    vertex_position_3d(_vbuff, _position_source[| _j], _position_source[| _j+1], _position_source[| _j+2]);
                }
                else
                {
                    vertex_position_3d(_vbuff, 0, 0, 0);
                }
                
                //Write the normal
                var _j = _normal_index_list[| _i];
                if (_j != undefined)
                {
                    _j *= 3;
                    vertex_normal(_vbuff, _normal_source[| _j], _normal_source[| _j+1], _normal_source[| _j+2]);
                }
                else
                {
                    vertex_normal(_vbuff, 0, 0, 0);
                }
                
                //Write the colour
                var _j = _colour_index_list[| _i];
                if (_j != undefined)
                {
                    _j *= 3;
                    var _colour = make_colour_rgb(255*_colour_source[| _j], 255*_colour_source[| _j+1], 255*_colour_source[| _j+2]);
                    vertex_color(_vbuff, _colour, 1.0);
                }
                else
                {
                    vertex_colour(_vbuff, c_white, 1.0);
                }
                
                //Write the UV
                var _j = _texcoord_index_list[| _i];
                if (_j != undefined)
                {
                    _j *= 2;
                    if (_flip_texcoords)
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[| _j], 1.0 - _texcoord_source[| _j+1]);
                    }
                    else
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[| _j], _texcoord_source[| _j+1]);
                    }
                }
                else
                {
                    vertex_texcoord(_vbuff, 0, 0);
                }
                
                //Iterate!
                if (_reverse_triangles)
                {
                    //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                    if (_r == 1) --_i else _i += 2;
                    ++_r;
                    if (_r >= 3) _r = 0;
                }
                else
                {
                    ++_i;
                }
            }
            
            #endregion
        break;
    }
    
    vertex_end(_vbuff);
    _object[@ eDotDaeVertexBuffer.VertexBuffer] = _vbuff;
    
    //Clean up the mess we made
    ds_list_destroy(_index_list);
    ds_list_destroy(_position_index_list);
    ds_list_destroy(_normal_index_list  );
    ds_list_destroy(_colour_index_list  );
    ds_list_destroy(_texcoord_index_list);
    
    ++_v;
}

if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("...finished building vertex buffers");

#endregion

//If we want to report the load time, do it!
if (DOTDAE_OUTPUT_LOAD_TIME) show_debug_message("dotdae_load(): Total time to load was " + string((get_timer() - _timer)/1000) + "ms");

//Return our data
return _container;