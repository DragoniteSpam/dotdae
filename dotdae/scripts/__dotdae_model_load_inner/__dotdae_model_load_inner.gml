function __dotdae_model_load_inner(_struct, _struct_name)
{
    var _parse_children = true;
    
    switch(_struct_name)
    {
        case "_root":
        break;
        
        case "xml prolog": //XML prolog, we can ignore this
        break;
        
        case "COLLADA":
        break;
        
        case "asset":
        break;
        
        case "library_effects":
        break;
        
        case "library_materials":
        break;
        
        case "library_images":
        break;
        
        case "library_geometries":
        break;
        
        case "library_visual_scenes": //Unsupported for now
            _parse_children = false;
        break;
        
        case "library_lights": //Unsupported for now
            _parse_children = false;
        break;
        
        case "library_cameras": //Unsupported for now
            _parse_children = false;
        break;
        
        case "library_animations": //Unsupported for now
            _parse_children = false;
        break;
        
        case "library_controllers":
        break;
        
        case "technique":
        break;
        
        case "profile_COMMON":
        break;
        
        case "image":
        break;
        
        case "controller":
        break;
        
        case "skin":
        break;
        
        case "joints":
        break;
        
        case "vertex_weights":
        break;
        
        case "v":
        break;
        
        case "name_array":
        case "Name_array": //Weird case insensitive tag name
        break;
    
        case "float_array":
        break;
    
        case "source":
        break;
    
        case "vcount":
        break;
    
        case "input":
        break;
        
        case "init_from":
        break;
        
        case "effect":
        break;
        
        case "phong":
        break;
        
        case "emission":
        break;
        
        case "ambient":
        break;
        
        case "diffuse":
        break;
        
        case "specular":
        break;
        
        case "shininess":
        break;
        
        case "index_of_refraction":
        break;
        
        case "color":
        break;
        
        case "texture":
        break;
        
        case "float":
        break;
        
        case "newparam":
        break;
        
        case "surface":
        break;
        
        case "sampler2D":
        break;
        
        case "material":
        break;
        
        case "instance_effect":
        break;
        
        case "geometry":
        break;
        
        case "mesh":
        break;
        
        case "accessor":
        break;
        
        case "vertices":
        break;
        
        case "triangles":
        break;
        
        case "polylist":
        break;
        
        case "p":
        break;
        
        case "extra":
        break;
        
        case "bump":
        break;
        
        case "transparent":
        break;
        
        case "technique_common":
        break;
        
        case "param":
        break;
        
        case "modified":
        break;
        
        case "unit":
        break;
        
        case "contributor":
        break;
        
        case "author":
        break;
        
        case "authoring_tool":
        break;
        
        case "created":
        break;
        
        case "up_axis":
        break;
        
        default:
            __dotdae_trace("WARNING! Unrecognised element type \"" + string(_struct_name) + "\" (typeof=" + string(typeof(_struct_name)), ")");
            //show_error("dotdae_model_load():\nUnrecognised element type \"" + string(_struct_name) + "\" (typeof=" + string(typeof(_struct_name)) + ")\n ", false);
        break;
        
        #endregion
    }
    
    if (_parse_children)
    {
        var _names = variable_struct_get_names(_struct);
        var _i = 0;
        repeat(array_length(_names))
        {
            var _name = _names[_i];
            if ((_name != "_prolog") && (_name != "_attr") && (_name != "_text"))
            {
                var _value = variable_struct_get(_struct, _name);
                if (is_struct(_value))
                {
                    __dotdae_model_load_inner(_value, _name);
                }
                else if (is_array(_value))
                {
                    var _j = 0;
                    repeat(array_length(_value))
                    {
                        __dotdae_model_load_inner(_value[_j], _name);
                        ++_j;
                    }
                }
            }
            
            ++_i;
        }
    }
}