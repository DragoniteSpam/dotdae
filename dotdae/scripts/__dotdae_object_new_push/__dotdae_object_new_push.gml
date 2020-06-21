/// @param name
/// @param type
/// @param size
/// @param trackingList

function __dotdae_object_new_push(_name, _type, _size, _list)
{
    var _array = __dotdae_object_new(_name, _type, _size, _list);

    ds_list_add(global.__dae_stack, _array);
    global.__dae_object_on_stack = _array;

    return _array;
}