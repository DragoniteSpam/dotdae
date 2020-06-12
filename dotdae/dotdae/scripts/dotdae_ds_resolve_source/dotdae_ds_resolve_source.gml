/// @param sourceName

var _source_name = argument0;

if (string_char_at(_source_name, 1) == "#") _source_name = string_delete(_source_name, 1, 1)

var _object = global.__dae_object_map[? _source_name];
switch(_object[__DOTDAE_TYPE_INDEX])
{
    case "source":
        return _object;
    break;
    
    case "vertices":
        var _input_array = _object[eDotDaeVertices.InputArray];
        var _input = _input_array[0];
        return dotdae_ds_resolve_source(_input[eDotDaeInput.Source]);
    break;
}

return undefined;