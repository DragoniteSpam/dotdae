global.dae_image_library = ds_map_create();

#macro DOTDAE_FORMAT_P    1
#macro DOTDAE_FORMAT_N    2
#macro DOTDAE_FORMAT_C    4
#macro DOTDAE_FORMAT_T    8
#macro DOTDAE_FORMAT_J   16
#macro DOTDAE_FORMAT_W   32

#region Internal macros

//Always date your work!
#macro __DOTDAE_VERSION   "0.0.0"
#macro __DOTDAE_DATE      "2020/06/13"

#macro __DOTDAE_NAME_INDEX   0 //Common position of an object's name
#macro __DOTDAE_TYPE_INDEX   1 //Common position of an object's type

#endregion