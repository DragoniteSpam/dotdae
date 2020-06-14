global.dae_image_library = ds_map_create();

//Used to express what vertex format a vertex buffer requires
#macro DOTDAE_FORMAT_P    1 //Position
#macro DOTDAE_FORMAT_N    2 //Normal
#macro DOTDAE_FORMAT_C    4 //Colour
#macro DOTDAE_FORMAT_T    8 //Texcoord
#macro DOTDAE_FORMAT_J   16 //Joint Index   N.B. Not implemented (2020-06-14)
#macro DOTDAE_FORMAT_W   32 //Joint Weight  N.B. Not implemented (2020-06-14)

#region Internal Object Enums

enum eDotDae
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    ObjectMap,
    EffectList,
    MaterialList,
    ImageList,
    GeometryList,
    VertexBufferList,
    __Size
}

enum eDotDaeImage
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    RelativePath,
    Sprite,
    Texture,
    __Size
}

enum eDotDaeSource
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    FloatArray,
    __Size
}

enum eDotDaeEffect
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    
    Parameters,
    Technique,
    
    Emission,
    EmissionImageName,
    EmissionTexture,
    
    Ambient,
    AmbientImageName,
    AmbientTexture,
    
    Diffuse,
    DiffuseImageName,
    DiffuseTexture,
    
    Specular,
    SpecularImageName,
    SpecularTexture,
    
    Shininess,
    ShininessImageName,
    ShininessTexture,
    
    Refraction,
    
    __Size
}

enum eDotDaeParameter
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    ParameterType,
    Value,
    __Size
}

enum eDotDaeMaterial
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    DisplayName,
    InstanceOf,
    __Size
}

enum eDotDaeGeometry
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    MeshArray,
    __Size
}

enum eDotDaeMesh
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    SourceArray,
    VertexBufferArray,
    __Size
}

enum eDotDaeFloatArray
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    List,
    __Size
}

enum eDotDaeInput
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    Semantic,
    Source,
    Offset,
    __Size
}

enum eDotDaeVertices
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    InputArray,
    __Size
}

enum eDotDaeVertexBuffer
{
    Name, //Must be the same as __DOTDAE_NAME_INDEX
    Type, //Must be the same as __DOTDAE_TYPE_INDEX
    Material,
    Effect,
    InputArray,
    VertexBuffer,
    PString,
    FormatCode,
    __Size
}

#endregion

#region Internal macros

//Always date your work!
#macro __DOTDAE_VERSION   "0.0.0"
#macro __DOTDAE_DATE      "2020/06/13"

#macro __DOTDAE_NAME_INDEX   0 //Common position of an object's name
#macro __DOTDAE_TYPE_INDEX   1 //Common position of an object's type

#endregion