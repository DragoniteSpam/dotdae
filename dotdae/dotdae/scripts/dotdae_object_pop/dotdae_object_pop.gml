ds_list_delete(global.__dae_object_stack, ds_list_size(global.__dae_object_stack)-1);
global.__dae_object = global.__dae_object_stack[| ds_list_size(global.__dae_object_stack)-1];
return global.__dae_object;