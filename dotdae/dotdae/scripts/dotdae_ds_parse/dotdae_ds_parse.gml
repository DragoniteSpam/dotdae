/// @param map
/// @param context

var _map     = argument0;
var _context = argument1;

var _tag            = _map[? "-name"    ];
var _children       = _map[? "-children"];
var _content        = _map[? "-content" ];
var _id             = _map[? "id"       ];
var _parse_children = true;
var _return         = undefined;
var _stack_size     = ds_list_size(global.__dae_object_stack);

switch(_tag)
{
    case "xml prolog":                     break;
    case "COLLADA":                        break;
    case "asset":      _context = "asset"; break;
    
    #region Libraries
    
    case "library_effects":       _context = "effect";       _parse_children = false; break; //Unsupported for now
    case "library_materials":     _context = "material";     _parse_children = false; break; //Unsupported for now
    case "library_images":        _context = "image";        _parse_children = false; break; //Unsupported for now
    case "library_geometries":    _context = "geometry";                              break;
    case "library_visual_scenes": _context = "visual scene"; _parse_children = false; break; //Unsupported for now
    case "library_lights":        _context = "light";        _parse_children = false; break; //Unsupported for now
    case "library_cameras":       _context = "camera";       _parse_children = false; break; //Unsupported for now
    case "library_animations":    _context = "animation";    _parse_children = false; break; //Unsupported for now
    
    #endregion
    
    #region Effect
    
    case "effect":
        enum eDotDaeEffect
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            __Size
        }
        
        global.__dae_object = dotdae_object_new_push(_id, _tag, eDotDaeEffect.__Size, global.__dae_effects_list);
    break;
    
    #endregion
    
    #region Geometry
    
    case "geometry":
        enum eDotDaeGeometry
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            MeshArray,
            __Size
        }
        
        var _object = dotdae_object_new_push(_id, _tag, eDotDaeGeometry.__Size, global.__dae_geometries_list);
        _object[@ eDotDaeGeometry.MeshArray] = [];
    break;
    
    case "mesh":
        enum eDotDaeMesh
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            SourceArray,
            VertexBuffer,
            __Size
        }
        
        var _parent = global.__dae_object;
        
        var _object = dotdae_object_new_push(_id, _tag, eDotDaeMesh.__Size, undefined);
        _object[@ eDotDaeMesh.SourceArray] = [];
        
        var _parent_mesh_array = _parent[eDotDaeGeometry.MeshArray];
        _parent_mesh_array[@ array_length_1d(_parent_mesh_array)] = _object;
        
        global.__dae_last_mesh = _object;
    break;
    
    case "source":
        enum eDotDaeSource
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            FloatArray,
            __Size
        }
        
        var _parent = global.__dae_object;
        
        var _object = dotdae_object_new_push(_id, _tag, eDotDaeSource.__Size, undefined);
        
        if (_context == "geometry")
        {
            var _parent_source_array = _parent[eDotDaeMesh.SourceArray];
            _parent_source_array[@ array_length_1d(_parent_source_array)] = _object;
        }
    break;
    
    case "float_array":
        enum eDotDaeFloatArray
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            List,
            __Size
        }
        
        var _object = dotdae_object_new(_id, _tag, eDotDaeFloatArray.__Size, undefined);
        _object[@ eDotDaeFloatArray.List] = dotdae_string_decompose_list(_content);
        global.__dae_object[@ eDotDaeSource.FloatArray] = _object;
    break;
    
    case "accessor":
        //We don't care about the accessor definition
    break;
    
    case "vertices":
        enum eDotDaeVertices
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            InputArray,
            __Size
        }
        
        var _object = dotdae_object_new_push(_id, _tag, eDotDaeVertices.__Size, undefined);
        _object[@ eDotDaeVertices.InputArray] = [];
    break;
    
    case "triangles":
    case "polylist":
        enum eDotDaeTriangles
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            Material,
            InputArray,
            __Size
        }
        
        var _parent = global.__dae_object;
        
        var _object = dotdae_object_new_push(_id, _tag, eDotDaeTriangles.__Size, undefined);
        _object[@ eDotDaeTriangles.Material  ] = _map[? "material"];
        _object[@ eDotDaeTriangles.InputArray] = [];
    break;
    
    case "input":
        enum eDotDaeInput
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            Semantic,
            Source,
            Offset,
            __Size
        }
        
        if (_context == "geometry")
        {
            var _parent = global.__dae_object;
            
            var _object = dotdae_object_new(_id, _tag, eDotDaeInput.__Size, undefined);
            _object[@ eDotDaeInput.Semantic] = _map[? "semantic"];
            _object[@ eDotDaeInput.Source  ] = _map[? "source"  ];
            _object[@ eDotDaeInput.Offset  ] = _map[? "offset"  ];
            
            if (_parent[__DOTDAE_TYPE_INDEX] == "vertices")
            {
                var _parent_source_array = _parent[eDotDaeVertices.InputArray];
                _parent_source_array[@ array_length_1d(_parent_source_array)] = _object;
            }
            else if ((_parent[__DOTDAE_TYPE_INDEX] == "triangles") || (_parent[__DOTDAE_TYPE_INDEX] == "polylist"))
            {
                var _parent_source_array = _parent[eDotDaeTriangles.InputArray];
                _parent_source_array[@ array_length_1d(_parent_source_array)] = _object;
            }
        }
    break;
    
    case "p":
        var _input_array = global.__dae_object[eDotDaeTriangles.InputArray];
        var _input_count = array_length_1d(_input_array);
        
        var _index_list  = dotdae_string_decompose_list(_content);
        var _index_count = ds_list_size(_index_list);
        
        var _vertex_count = _index_count div _input_count;
        
        var _position_index_list = ds_list_create();
        var _normal_index_list   = ds_list_create();
        var _colour_index_list   = ds_list_create();
        var _texcoord_index_list = ds_list_create();
        
        var _position_source = undefined;
        var _normal_source   = undefined;
        var _colour_source   = undefined;
        var _texcoord_source = undefined;
        
        var _i = 0;
        repeat(_input_count)
        {
            var _input = _input_array[_i];
            
            var _source = dotdae_ds_resolve_source(_input[eDotDaeInput.Source]);
            var _source_array = _source[eDotDaeSource.FloatArray];
            
            var _collection_list = undefined;
            switch(_input[eDotDaeInput.Semantic])
            {
                case "POSITION": _collection_list = _position_index_list; _position_source = _source_array[eDotDaeFloatArray.List]; break;
                case "VERTEX":   _collection_list = _position_index_list; _position_source = _source_array[eDotDaeFloatArray.List]; break;
                case "NORMAL":   _collection_list = _normal_index_list;   _normal_source   = _source_array[eDotDaeFloatArray.List]; break;
                case "COLOR":    _collection_list = _colour_index_list;   _colour_source   = _source_array[eDotDaeFloatArray.List]; break;
                case "TEXCOORD": _collection_list = _texcoord_index_list; _texcoord_source = _source_array[eDotDaeFloatArray.List]; break;
            }
            
            var _j = real(_input[eDotDaeInput.Offset]);
            var _k = 0;
            repeat(_vertex_count)
            {
                ds_list_add(_collection_list, _index_list[| _j]);
                _j += _input_count;
                ++_k;
            }
            
            ++_i;
        }
        
        var _vbuff = vertex_create_buffer();
        vertex_begin(_vbuff, global.__dae_vertex_format);
        
        var _i = 0;
        repeat(_vertex_count)
        {
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
            
            var _j = _texcoord_index_list[| _i];
            if (_j != undefined)
            {
                _j *= 2;
                if (global.__dae_flip_texcoords)
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
            
            ++_i;
        }
        
        vertex_end(_vbuff);
        global.__dae_last_mesh[@ eDotDaeMesh.VertexBuffer] = _vbuff;
    break;
    
    #endregion
}

if (_parse_children && (_children != undefined))
{
    var _i = 0;
    repeat(ds_list_size(_children))
    {
        dotdae_ds_parse(_children[| _i], _context);
        ++_i;
    }
}

//If the stack size has changed, pop the object we pushed!
if (_stack_size != ds_list_size(global.__dae_object_stack)) dotdae_object_pop();

return _return;