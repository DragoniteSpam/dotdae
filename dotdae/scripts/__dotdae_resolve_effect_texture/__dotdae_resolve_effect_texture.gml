/// @param objectMap
/// @param effectArray
/// @param imageNameField
/// @param textureField

function __dotdae_resolve_effect_texture(_object_map, _effect, _name_field, _texture_field)
{
    var _name = _effect[_name_field];
    if (_name != undefined)
    {
        var _effect_params = _effect[eDotDaeEffect.Parameters];
        var _param = _effect_params[? _name];
            _name  = _param[eDotDaeParameter.Value];
            _param = _effect_params[? _name];
            _name  = _param[eDotDaeParameter.Value];
        var _image = _object_map[? _name];
    
        _effect[@ _texture_field] = _image[eDotDaeImage.Texture];
    }
    else
    {
        _effect[@ _texture_field] = -1;
    }
}