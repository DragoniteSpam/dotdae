/// @param [value]
/// @param ...
function __dotdae_trace() {

    var _string = "";
    var _i = 0;
    repeat(argument_count)
    {
        _string += string(argument[_i]);
        ++_i;
    }

    show_debug_message("dotdae: " + _string);
    return _string;
}