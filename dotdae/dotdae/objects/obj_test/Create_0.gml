//Initialise dotdae
dotdae_init();

//Optional function that simulates a texture being loaded from disc
//This is useful if you don't want to package textures in separate files
dotdae_image_add(tex_lion, "sponza/lion.png");

//Load our .dae from disk. This might take a while!
//The script returns a dotdae model (in reality, an array) that we can draw in the Draw event
container = dotdae_model_load_file("sponza.dae", true, false);

//Mouse lock variables (press F3 to lock the mouse and use mouselook)
mouse_lock = false;
mouse_lock_timer = 0;

//Some variables to track the camera
cam_x     = 0;
cam_y     = 10;
cam_z     = 0;
cam_yaw   = -60;
cam_pitch = 0;
cam_dx    = -dcos(cam_pitch)*dsin(cam_yaw);
cam_dy    = -dsin(cam_pitch);
cam_dz    =  dcos(cam_pitch)*dcos(cam_yaw);

//Smoothed fps_real variable
fps_smoothed = 60;
show_info = true;