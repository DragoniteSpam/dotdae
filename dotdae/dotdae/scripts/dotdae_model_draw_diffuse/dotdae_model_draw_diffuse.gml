/// @param model

var _model = argument0;

shader_set(shd_dotdae_pnt);

var _g = 0;
repeat(ds_list_size(global.__dae_geometries_list))
{
    var _geometry = global.__dae_geometries_list[| _g];
    var _mesh_array = _geometry[eDotDaeGeometry.MeshArray];
    
    var _m = 0;
    repeat(array_length_1d(_mesh_array))
    {
        var _mesh = _mesh_array[_m];
        var _vbuff = _mesh[eDotDaeMesh.VertexBuffer];
        vertex_submit(_vbuff, pr_trianglelist, -1);
        ++_m;
    }
    
    ++_g;
}

shader_reset();