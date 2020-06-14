/// @param container

var _container = argument0;

var _object_map    = _container[eDotDae.ObjectMap   ];
var _geometry_list = _container[eDotDae.GeometryList];

var _g = 0;
repeat(ds_list_size(_geometry_list))
{
    var _geometry = _geometry_list[| _g];
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
            var _effect = _vertex_buffer[eDotDaeVertexBuffer.Effect];
            vertex_submit(_vertex_buffer[eDotDaeVertexBuffer.VertexBuffer], pr_trianglelist, _effect[eDotDaeEffect.DiffuseTexture]);
            ++_v;
        }
        
        ++_m;
    }
    
    ++_g;
}