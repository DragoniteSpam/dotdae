/// Loads a .dae (Collada) file from disk and turns it into a vertex buffer
/// @jujuadams
/// 
/// This isn't a full implementation of the .dae format, but it's a starting point at least
/// 
/// Texture coordinates for a .dae model will typically be normalised and in the
/// range (0,0) -> (1,1). Please use another script to remap texture coordinates
/// to GameMaker's atlased UV space.
/// 
/// @param filename   File to read from

function dotdae_model_load(_buffer)
{
    if (DOTDAE_OUTPUT_LOAD_TIME) var _timer = get_timer();
    
    var _flip_texcoords    = global.__dotdae_flip_texcoord_v;
    var _reverse_triangles = global.__dotdae_reverse_triangles;

    //Create a bunch of data structures to contain data
    var _dae_object_map          = { };
    var _dae_effects_list        = [];
    var _dae_materials_list      = [];
    var _dae_images_list         = [];
    var _dae_geometries_list     = [];
    var _dae_vertex_buffers_list = [];
    var _dae_controllers_list    = [];

    //Make a container array and add the data structures to it
    var _container = array_create(eDotDae.__Size, undefined);
    _container[@ eDotDae.Name            ] = "<unnamed>";
    _container[@ eDotDae.Type            ] = "containter";
    _container[@ eDotDae.ObjectMap       ] = _dae_object_map;
    _container[@ eDotDae.EffectList      ] = _dae_effects_list;
    _container[@ eDotDae.MaterialList    ] = _dae_materials_list;
    _container[@ eDotDae.ImageList       ] = _dae_images_list;
    _container[@ eDotDae.GeometryList    ] = _dae_geometries_list;
    _container[@ eDotDae.VertexBufferList] = _dae_vertex_buffers_list;
    _container[@ eDotDae.ControllerList  ] = _dae_controllers_list;

    //Define some global variables that'll get referenced in __dotdae_model_load_inner()
    global.__dae_stack               = [];
    global.__dae_object_map          = _dae_object_map;
    global.__dae_effects_list        = _dae_effects_list;
    global.__dae_materials_list      = _dae_materials_list;
    global.__dae_images_list         = _dae_images_list;
    global.__dae_geometries_list     = _dae_geometries_list;
    global.__dae_vertex_buffers_list = _dae_vertex_buffers_list;
    global.__dae_controllers_list    = _dae_controllers_list;

    //Parse the .dae XML found in the buffer
    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Parsing XML... (This may take some time)");
    var _xml = buffer_xml_decode(_buffer, 0, buffer_get_size(_buffer));
    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("...finished parsing XML");

    //Traverse the generated XML and build a data structure we can use
    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Traversing data structure...");
    __dotdae_model_load_inner(_xml, undefined);
    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("...finished traversing data structure");

    #region Pre-process effect -> texture so we need less code in dotdae_model_draw()

    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Pre-processing effect -> texture links");
    var _e = 0;
    repeat(array_length(_dae_effects_list))
    {
        var _effect = _dae_effects_list[_e];
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
    repeat(array_length(_dae_vertex_buffers_list))
    {
        //Grab our object definition from our list of vertex buffers
        var _object = _dae_vertex_buffers_list[_v];
    
        //Get our material data
        var _material_name = _object[eDotDaePolyList.Material];
        var _material = (_material_name != undefined) ? _dae_object_map[$ _material_name] : undefined;
    
        if (is_array(_material))
        {
            //Set the vertex buffer's effect to the material's effect
            _object[@ eDotDaePolyList.Effect] = _material[eDotDaeMaterial.InstanceOf];
        }
        else
        {
            __dotdae_trace("WARNING! \"", _object[eDotDaePolyList.Name], "\" has an invalid material, or the material cannot be found (material=\"", _material_name, "\")");
        }
    
        ++_v;
    }

    #endregion

    #region Iterate over all the vertex buffers we need to make, and make them!

    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Building vertex buffers...");
    var _v = 0;
    repeat(array_length(_dae_vertex_buffers_list))
    {
        //Grab our object definition from our list of vertex buffers
        var _object = _dae_vertex_buffers_list[_v];
    
        if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("Building \"", _object[eDotDaePolyList.Name], "\" using material \"", _object[eDotDaePolyList.Material], "\"");
    
        var _pstring         = _object[eDotDaePolyList.PString       ];
        var _input_array     = _object[eDotDaePolyList.InputArray    ]; //Get our array that describes the vertex buffer layout
        var _controller_name = _object[eDotDaePolyList.SkinController];
    
        //Break down the string found in the <p> tag into a list of indexes
        var _index_list  = __dotdae_string_decompose_list(_pstring, true);
        var _index_count = array_length(_index_list);
    
        //Figure out how many vertices we have
        //This *should* match the value we found in the file
        //TODO - Check that these two values match up and report an error if not (!)
        var _input_count = array_length(_input_array);
        var _vertex_count = _index_count div _input_count;
    
        if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("          ^-- triangles = ", _vertex_count/3);
        if ((_vertex_count/3) != _object[eDotDaePolyList.Count]) __dotdae_trace("WARNING! \"", _object[eDotDaePolyList.Name], "\" triangle count (", _vertex_count/3, ") doesn't match triangle count in source file (", _object[eDotDaePolyList.Count], ")");
    
        #region Extract position/normal/colour/texcoord data from the geometry definition
    
        //Create some variables...
        var _position_index_list = [];
        var _normal_index_list   = [];
        var _colour_index_list   = [];
        var _texcoord_index_list = [];
        var _position_source     = undefined;
        var _normal_source       = undefined;
        var _colour_source       = undefined;
        var _texcoord_source     = undefined;
    
        //Iterate over our layout and reorganise the data so we can handle it more safely
        var _i = 0;
        repeat(_input_count)
        {
            var _input = _input_array[_i];
            var _source_name = _input[eDotDaeInput.Source  ];
            var _semantic    = _input[eDotDaeInput.Semantic];
        
            if (string_char_at(_source_name, 1) == "#") _source_name = string_delete(_source_name, 1, 1);
            var _source = _dae_object_map[$ _source_name];
        
            //Handle VERTEX -> POSITION weirdness
            if (_source[__DOTDAE_TYPE_INDEX] == "vertices")
            {
                var _temp_input_array = _source[eDotDaeVertices.InputArray];
                var _temp_input = _temp_input_array[0];
            
                _source_name = _temp_input[eDotDaeInput.Source  ];
                _semantic    = _temp_input[eDotDaeInput.Semantic];
            
                if (string_char_at(_source_name, 1) == "#") _source_name = string_delete(_source_name, 1, 1);
                _source = _dae_object_map[$ _source_name];
            }
        
            var _source_array = _source[eDotDaeSource.FloatArray];
        
            var _collection_list = undefined;
            switch(_semantic)
            {
                case "POSITION":
                    _collection_list = _position_index_list;                  //Set our sublist to be the position one
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
                    array_push(_collection_list, _index_list[_j]);
                    _j += _input_count;
                }
            }
            
            ++_i;
        }
    
        #endregion
    
        #region Extract joint weights from the controller definition
    
        //Create some variables...
        var _joint_vertex_count  = 0;
        var _vstring_lookup_list = [];
        var _vcount_list         = undefined;
        var _v_list              = undefined;
        var _weight_source       = undefined;
    
        if (_controller_name != undefined) {
        var _controller = _dae_object_map[$ _controller_name];
            if (_controller != undefined)
            {
                var _vertex_weights = _controller[eDotDaeController.VertexWeights];
                _joint_vertex_count = _vertex_weights[eDotDaeVertexWeights.Count];
        
                _v_list      = __dotdae_string_decompose_list(_vertex_weights[eDotDaeVertexWeights.VString     ], true);
                _vcount_list = __dotdae_string_decompose_list(_vertex_weights[eDotDaeVertexWeights.VCountString], true);
        
                var _i = 0;
                var _p = 0;
                repeat(array_length(_vcount_list))
                {
                    array_push(_vstring_lookup_list, _p);
                    _p += 2*_vcount_list[_i];
                }
        
                //Find the joint weight values
                var _input_array = _vertex_weights[eDotDaeVertexWeights.InputArray];
                var _i = 0;
                repeat(array_length(_input_array))
                {
                    var _input = _input_array[_i];
                    var _source_name = _input[eDotDaeInput.Source  ];
                    var _semantic    = _input[eDotDaeInput.Semantic];
            
                    if (_semantic == "WEIGHT")
                    {
                        if (string_char_at(_source_name, 1) == "#") _source_name = string_delete(_source_name, 1, 1);
                        var _source = _dae_object_map[$ _source_name];
                        var _source_array = _source[eDotDaeSource.FloatArray];
                        _weight_source = _source_array[eDotDaeFloatArray.List];
                    }
            
                    ++_i;
                }
            }
        }
    
        #endregion
    
        //Figure out a format code based on which index lists have sufficient data
        var _format_code = 0;
        if (array_length(_position_index_list) >= _vertex_count) _format_code |= DOTDAE_FORMAT_P;
        if (array_length(_normal_index_list  ) >= _vertex_count) _format_code |= DOTDAE_FORMAT_N;
        if (array_length(_colour_index_list  ) >= _vertex_count) _format_code |= DOTDAE_FORMAT_C;
        if (array_length(_texcoord_index_list) >= _vertex_count) _format_code |= DOTDAE_FORMAT_T;
        if ((_joint_vertex_count >= array_length(_position_source)/3) && (_weight_source != undefined)) _format_code |= DOTDAE_FORMAT_J;
        _object[@ eDotDaePolyList.FormatCode] = _format_code;
    
        if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("          ^-- format code = ", _format_code);
    
        //Now create our vertex buffer based on what format code we have
        //This seems like a long way round of doing things, but it ends up being more efficient
        //By checking what format to use *outside* the vertex writing loop we avoid potentially hundreds of thousands of unnecessary if-statements
        var _vbuff = vertex_create_buffer();
    
        switch(_format_code)
        {
            case (DOTDAE_FORMAT_P | DOTDAE_FORMAT_N | DOTDAE_FORMAT_C | DOTDAE_FORMAT_T | DOTDAE_FORMAT_J):
                #region Position, Normal, Colour, Texcoord, Joint Weights
            
                if (_reverse_triangles) show_error("dotdae:\nReversed triangles not supported for models with joint weights\n ", false);
            
                vertex_begin(_vbuff, global.__dae_vformat_pnctj);
            
                //Write all of our data - position, normal, colour, texcoord
                var _i = 0;
                var _j = 0;
                repeat(_vertex_count)
                {
                    //Write the position
                    var _v = _position_index_list[_i];
                    var _q = 3*_v;
                    vertex_position_3d(_vbuff, _position_source[_q], _position_source[_q+1], _position_source[_q+2]);
                
                    //Write the normal
                    var _q = 3*_normal_index_list[_i];
                    vertex_normal(_vbuff, _normal_source[_q], _normal_source[_q+1], _normal_source[_q+2]);
                
                    //Write the colour
                    var _q = 3*_colour_index_list[_i];
                    var _colour = make_colour_rgb(255*_colour_source[_q], 255*_colour_source[_q+1], 255*_colour_source[_q+2]);
                    vertex_color(_vbuff, _colour, 1.0);
                
                    //Write the UV
                    var _q = 2*_texcoord_index_list[_i];
                    if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_q], 1.0 - _texcoord_source[_q+1]);
                    }
                    else
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_q], _texcoord_source[_q+1]);
                    }
                
                    //Write joint indexes/weights
                    var _pos = _vstring_lookup_list[_v];
                    var _joint_count = _vcount_list[_v];
                    switch(_joint_count)
                    {
                        case 0:
                            vertex_float4(_vbuff, 0, 0, 0, 0);
                            vertex_float4(_vbuff, 0, 0, 0, 0);
                        break;
                    
                        case 1:
                            vertex_float4(_vbuff,                _v_list[_pos   ], 0, 0, 0);
                            vertex_float4(_vbuff, _weight_source[_v_list[_pos+1]], 0, 0, 0);
                        break;
                    
                        case 2:
                            vertex_float4(_vbuff,                _v_list[_pos  ] ,                _v_list[_pos+2] , 0, 0);
                            vertex_float4(_vbuff, _weight_source[_v_list[_pos+1]], _weight_source[_v_list[_pos+3]], 0, 0);
                        break;
                    
                        case 3:
                            vertex_float4(_vbuff,                _v_list[_pos  ] ,                _v_list[_pos+2] ,                _v_list[_pos+4] , 0);
                            vertex_float4(_vbuff, _weight_source[_v_list[_pos+1]], _weight_source[_v_list[_pos+3]], _weight_source[_v_list[_pos+5]], 0);
                        break;
                    
                        case 4:
                            vertex_float4(_vbuff,                _v_list[_pos  ] ,                _v_list[_pos+2] ,                _v_list[_pos+4] ,                _v_list[_pos+6] );
                            vertex_float4(_vbuff, _weight_source[_v_list[_pos+1]], _weight_source[_v_list[_pos+3]], _weight_source[_v_list[_pos+5]], _weight_source[_v_list[_pos+7]]);
                        break;
                    
                        //Higher order joint counts we just ignore. I dunno why people are making models with >4 joint weights per vertex, it's rare for a game engine to support that
                        default:
                            __dotdae_trace("WARNING! Joint count ", _joint_count, " exceeds maximum (4)");
                            vertex_float4(_vbuff,                _v_list[_pos  ] ,                _v_list[_pos+2] ,                _v_list[_pos+4] ,                _v_list[_pos+6] );
                            vertex_float4(_vbuff, _weight_source[_v_list[_pos+1]], _weight_source[_v_list[_pos+3]], _weight_source[_v_list[_pos+5]], _weight_source[_v_list[_pos+7]]);
                        break;
                    }
                
                    //Iterate!
                    ++_i;
                }
            
                #endregion
            break;
        
            case (DOTDAE_FORMAT_P | DOTDAE_FORMAT_N | DOTDAE_FORMAT_C | DOTDAE_FORMAT_T):
                #region Position, Normal, Colour, Texcoord
            
                vertex_begin(_vbuff, global.__dae_vformat_pnct);
            
                //Write all of our data - position, normal, colour, texcoord
                var _i = 0;
                var _r = 0;
                repeat(_vertex_count)
                {
                    //Write the position
                    var _j = 3*_position_index_list[_i];
                    vertex_position_3d(_vbuff, _position_source[_j], _position_source[_j+1], _position_source[_j+2]);
                
                    //Write the normal
                    var _j = 3*_normal_index_list[_i];
                    vertex_normal(_vbuff, _normal_source[_j], _normal_source[_j+1], _normal_source[_j+2]);
                
                    //Write the colour
                    var _j = 3*_colour_index_list[_i];
                    var _colour = make_colour_rgb(255*_colour_source[_j], 255*_colour_source[_j+1], 255*_colour_source[_j+2]);
                    vertex_color(_vbuff, _colour, 1.0);
                
                    //Write the UV
                    var _j = 2*_texcoord_index_list[_i];
                    if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_j], 1.0 - _texcoord_source[_j+1]);
                    }
                    else
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_j], _texcoord_source[_j+1]);
                    }
                
                    //Iterate!
                    if (_reverse_triangles) //TODO - Move this if-check outside the loop?
                    {
                        //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                        if (_r == 1) _i-- else _i += 2;
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
        
            case (DOTDAE_FORMAT_P | DOTDAE_FORMAT_C | DOTDAE_FORMAT_T):
                #region Position, Colour, Texcoord
            
                vertex_begin(_vbuff, global.__dae_vformat_pnct);
            
                //Write position, colour, texcoord
                var _i = 0;
                var _r = 0;
                repeat(_vertex_count)
                {
                    //Write the position
                    var _j = 3*_position_index_list[_i];
                    vertex_position_3d(_vbuff, _position_source[_j], _position_source[_j+1], _position_source[_j+2]);
                
                    //Write a default null normal
                    vertex_normal(_vbuff, 0, 0, 0);
                
                    //Write the colour
                    var _j = 3*_colour_index_list[_i];
                    var _colour = make_colour_rgb(255*_colour_source[_j], 255*_colour_source[_j+1], 255*_colour_source[_j+2]);
                    vertex_color(_vbuff, _colour, 1.0);
                
                    //Write the UV
                    var _j = 2*_texcoord_index_list[_i];
                    if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_j], 1.0 - _texcoord_source[_j+1]);
                    }
                    else
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_j], _texcoord_source[_j+1]);
                    }
                
                    //Iterate!
                    if (_reverse_triangles) //TODO - Move this if-check outside the loop?
                    {
                        //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                        if (_r == 1) _i-- else _i += 2;
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
        
            case (DOTDAE_FORMAT_P | DOTDAE_FORMAT_N | DOTDAE_FORMAT_T):
                #region Position, Normal, Texcoord
            
                vertex_begin(_vbuff, global.__dae_vformat_pnct);
            
                //Write position, normal, texcoord
                var _i = 0;
                var _r = 0;
                repeat(_vertex_count)
                {
                    //Write the position
                    var _j = 3*_position_index_list[_i];
                    vertex_position_3d(_vbuff, _position_source[_j], _position_source[_j+1], _position_source[_j+2]);
                
                    //Write the normal
                    var _j = 3*_normal_index_list[_i];
                    vertex_normal(_vbuff, _normal_source[_j], _normal_source[_j+1], _normal_source[_j+2]);
                
                    //Write a default colour
                    vertex_color(_vbuff, DOTDAE_DEFAULT_DIFFUSE_RGB, 1.0);
                
                    //Write the UV
                    var _j = 2*_texcoord_index_list[_i];
                    if (_flip_texcoords) //TODO - Move this if-check outside the loop?
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_j], 1.0 - _texcoord_source[_j+1]);
                    }
                    else
                    {
                        vertex_texcoord(_vbuff, _texcoord_source[_j], _texcoord_source[_j+1]);
                    }
                
                    //Iterate!
                    if (_reverse_triangles) //TODO - Move this if-check outside the loop?
                    {
                        //Generate a ACB triangles by iterating using a {+2, -1, +2} pattern
                        if (_r == 1) _i-- else _i += 2;
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
            
                vertex_begin(_vbuff, global.__dae_vformat_pnct);

                //If this specific format code isn't supported then write using some slow generic code
                __dotdae_trace("WARNING! Using slow vertex writer for unsupported format code (", _format_code, ")");
            
                var _i = 0;
                var _r = 0;
                repeat(_vertex_count)
                {
                    //Write the position
                    var _j = _position_index_list[_i];
                    if (_j != undefined)
                    {
                        _j *= 3;
                        vertex_position_3d(_vbuff, _position_source[_j], _position_source[_j+1], _position_source[_j+2]);
                    }
                    else
                    {
                        vertex_position_3d(_vbuff, 0, 0, 0);
                    }
                
                    //Write the normal
                    var _j = _normal_index_list[_i];
                    if (_j != undefined)
                    {
                        _j *= 3;
                        vertex_normal(_vbuff, _normal_source[_j], _normal_source[_j+1], _normal_source[_j+2]);
                    }
                    else
                    {
                        vertex_normal(_vbuff, 0, 0, 0);
                    }
                
                    //Write the colour
                    var _j = _colour_index_list[_i];
                    if (_j != undefined)
                    {
                        _j *= 3;
                        var _colour = make_colour_rgb(255*_colour_source[_j], 255*_colour_source[_j+1], 255*_colour_source[_j+2]);
                        vertex_color(_vbuff, _colour, 1.0);
                    }
                    else
                    {
                        vertex_colour(_vbuff, c_white, 1.0);
                    }
                
                    //Write the UV
                    var _j = _texcoord_index_list[_i];
                    if (_j != undefined)
                    {
                        _j *= 2;
                        if (_flip_texcoords)
                        {
                            vertex_texcoord(_vbuff, _texcoord_source[_j], 1.0 - _texcoord_source[_j+1]);
                        }
                        else
                        {
                            vertex_texcoord(_vbuff, _texcoord_source[_j], _texcoord_source[_j+1]);
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
                        if (_r == 1) _i-- else _i += 2;
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
        _object[@ eDotDaePolyList.VertexBuffer] = _vbuff;
    
        ++_v;
    }

    if (DOTDAE_OUTPUT_DEBUG) __dotdae_trace("...finished building vertex buffers");

    #endregion

    //Clean up
    global.__dae_stack               = undefined;
    global.__dae_object_map          = undefined;
    global.__dae_object_on_stack     = undefined;
    global.__dae_effects_list        = undefined;
    global.__dae_materials_list      = undefined;
    global.__dae_images_list         = undefined;
    global.__dae_geometries_list     = undefined;
    global.__dae_vertex_buffers_list = undefined;

    //If we want to report the load time, do it!
    if (DOTDAE_OUTPUT_LOAD_TIME) show_debug_message("dotdae_load(): Total time to load was " + string((get_timer() - _timer)/1000) + "ms");

    //Return our data
    return _container;
}