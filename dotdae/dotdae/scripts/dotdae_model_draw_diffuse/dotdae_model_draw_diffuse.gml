/// @param model

var _model = argument0;

shader_set(shd_dotdae_pnct);

var _g = 0;
repeat(ds_list_size(global.__dae_geometries_list))
{
    var _geometry = global.__dae_geometries_list[| _g];
    var _mesh_array = _geometry[eDotDaeGeometry.MeshArray];
    
    var _m = 0;
    repeat(array_length_1d(_mesh_array))
    {
        var _mesh = _mesh_array[_m];
        var _vbuff_array = _mesh[eDotDaeMesh.VertexBufferArray];
        
        var _v = 0;
        repeat(array_length_1d(_vbuff_array))
        {
            var _vertex_buffer = _vbuff_array[_v];
            var _material_name = _vertex_buffer[eDotDaeVertexBuffer.Material];
            var _texture       = -1;
            
            var _material = global.__dae_object_map[? _material_name];
            var _effect_name = _material[eDotDaeMaterial.InstanceOf];
            _effect_name = string_delete(_effect_name, 1, 1);
            
            var _effect = global.__dae_object_map[? _effect_name];
            
            var _sampler_name = _effect[eDotDaeEffect.DiffuseMap];
            if (_sampler_name != undefined)
            {
                var _effect_parameters = _effect[eDotDaeEffect.Parameters];
                var _sampler_param = _effect_parameters[? _sampler_name];
                var _surface_name  = _sampler_param[eDotDaeParameter.Value];
                var _surface_param = _effect_parameters[? _surface_name];
                var _image_name    = _surface_param[eDotDaeParameter.Value];
                var _image         = global.__dae_object_map[? _image_name];
                    _texture       = _image[eDotDaeImage.Texture];
            }
            
            vertex_submit(_vertex_buffer[eDotDaeVertexBuffer.VertexBuffer], pr_trianglelist, _texture);
            
            ++_v;
        }
        
        ++_m;
    }
    
    ++_g;
}

shader_reset();