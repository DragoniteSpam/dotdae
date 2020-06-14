/// @param name
/// @param type
/// @param size
/// @param trackingList

var _array = __dotdae_object_new(argument0, argument1, argument2, argument3);

ds_list_add(global.__dae_object_stack, _array);
global.__dae_object = _array;

return _array;