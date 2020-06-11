var _buffer = buffer_load("box.dae");
var _json = buffer_xml_decode(_buffer, 0, buffer_get_size(_buffer));
buffer_delete(_buffer);

var _buffer = buffer_load("colladabox.dae");
var _json = buffer_xml_decode(_buffer, 0, buffer_get_size(_buffer));
buffer_delete(_buffer);

var _buffer = buffer_load("monkey.dae");
var _json = buffer_xml_decode(_buffer, 0, buffer_get_size(_buffer));
buffer_delete(_buffer);

var _buffer = buffer_load("model.dae");
var _json = buffer_xml_decode(_buffer, 0, buffer_get_size(_buffer));
buffer_delete(_buffer);

var _buffer = buffer_load("sponza.dae");
var _json = buffer_xml_decode(_buffer, 0, buffer_get_size(_buffer));
buffer_delete(_buffer);