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
    
    case "library_effects":       _context = "effect";       break;
    case "library_materials":     _context = "material";     break;
    case "library_images":        _context = "image";        break;
    case "library_geometries":    _context = "geometry";     break;
    case "library_visual_scenes": _context = "visual scene"; break;
    case "library_lights":        _context = "light";        break;
    case "library_cameras":       _context = "camera";       break;
    
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
        
        var _parent_source_array = _parent[eDotDaeGeometry.MeshArray];
        _parent_source_array[@ array_length_1d(_parent_source_array)] = _object;
    break;
    
    case "float_array":
        enum eDotDaeFloatArray
        {
            Name, //Must be the same as __DOTDAE_NAME_INDEX
            Type, //Must be the same as __DOTDAE_TYPE_INDEX
            Array,
            __Size
        }
        
        var _object = dotdae_object_new(_id, _tag, eDotDaeFloatArray.__Size, undefined);
        _object[@ eDotDaeFloatArray.Array] = dotdae_string_array_decompose(_content);
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
        else if (_parent[__DOTDAE_TYPE_INDEX] == "triangles")
        {
            var _parent_source_array = _parent[eDotDaeTriangles.InputArray];
            _parent_source_array[@ array_length_1d(_parent_source_array)] = _object;
        }
    break;
    
    case "p":
        var _input_array    = global.__dae_object[eDotDaeTriangles.InputArray];
        var _semantic_array = array_create(array_length_1d(_input_array), undefined);
        var _data_array     = array_create(array_length_1d(_input_array), undefined);
        
        var _i = 0;
        repeat(array_length_1d(_input_array))
        {
            var _input       = _input_array[_i];
            var _source      = dotdae_ds_resolve_source(_input[eDotDaeInput.Source]);
            var _float_array = _source[eDotDaeSource.FloatArray];
            
            _semantic_array[@ _i] = _input[eDotDaeInput.Semantic];
            _data_array[@ _i] = _float_array[eDotDaeFloatArray.Array];
            
            ++_i;
        }
        
        var _index_array = dotdae_string_array_decompose(_content);
        
        var _vbuff = vertex_create_buffer();
        vertex_begin(_vbuff, global.__dae_vertex_format);
        
        var _i = 0;
        var _j = 0;
        repeat(array_length_1d(_index_array))
        {
            var _index = _index_array[_i];
            var _data = _data_array[_j];
            switch(_semantic_array[_j])
            {
                case "VERTEX":
                    _index *= 3;
                    vertex_position_3d(_vbuff, _data[_index], _data[_index+1], _data[_index+2]);
                    //show_debug_message("pos = (" + string(_data[_index]) + "," + string(_data[_index+1]) + "," + string(_data[_index+2]) + ")");
                break;
                
                case "NORMAL":
                    _index *= 3;
                    vertex_normal(_vbuff, _data[_index], _data[_index+1], _data[_index+2]);
                    //show_debug_message("norm = (" + string(_data[_index]) + "," + string(_data[_index+1]) + "," + string(_data[_index+2]) + ")");
                break;
                
                case "TEXCOORD":
                    _index *= 2;
                    vertex_texcoord(_vbuff, _data[_index], _data[_index+1]);
                    //show_debug_message("uv = (" + string(_data[_index]) + "," + string(_data[_index+1]) + ")");
                break;
            }
            
            ++_i;
            ++_j;
            if (_j >= 3) _j = 0;
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