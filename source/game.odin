package game

import "core:fmt"
import "core:math/linalg"
import "core:math"
import "core:math/rand"
import "base:runtime"
import rl "vendor:raylib"
import noise"core:math/noise"
import clay "/clay-odin"
import "core:log"
import "core:thread"



mat:rl.Material

init::proc(){
	// init_thred_pool()
	// rl.InitAudioDevice()
	// init_clay_ui()
	// init_sounds()
	// init_shaders()
	// init_atlases()
	// init_box_2d()
	// init_global_animations()
	// init_defalts()
	// init_tile_data(&g.t_data)
	register_events()
	init_world()

	// log_system_info()

	// g.world.name="test_world"
	
	// rl.SetTargetFPS(10)
	// g.cam.position = {0,0,-50}
	// g.cam.target = {0,0,0}
	
	// g.cam.projection=.ORTHOGRAPHIC
	// g.cam.up = {0,-1,0}

	// mat= rl.LoadMaterialDefault()
	// mat.shader=g.as.shaders.bace
	// temp:[2]f32={cast(f32)g.atlas.width,cast(f32)g.atlas.height}
	// rl.SetShaderValueV(g.as.shaders.bace,rl.GetShaderLocation(g.as.shaders.bace,"at_size"),cast(rawptr)(&temp),.VEC2,1)
	// mat.maps[rl.MaterialMapIndex.ALBEDO].texture=g.atlas
	// mat.maps[rl.MaterialMapIndex.ALBEDO].color = {255,255,255,255}


	// g.world_gen_thread=thread.create_and_start(world_gen_thread,context)
	
	// rand.reset(rand.uint64()+cast(u64)(rl.GetTime()*100000000000))

}





update :: proc() {
	free_all(context.temp_allocator)
	maintain_input_info()
	maintain_window_info()
	maintain_timers()
	calc_particles()
	do_inputs()
	update_world()
	if is_input_event(.jump,require_d = true,ignore_p = true){
		w:=&world[world_w/2][world_h/2]
		w.id=.sand
		x:=rand.float32()*2-1
		y:=rand.float32()*2-1
		w.vector = {x,y}

		w=&world[world_w/2+1][world_h/2]
		w.id=.sand
		x=rand.float32()*5-1
		y=rand.float32()*5-1
		w.vector = {x,y}
		
		w=&world[world_w/2-1][world_h/2]
		w.id=.sand
		x=rand.float32()*2-1
		y=rand.float32()*2-1
		w.vector = {x,y}

		w=&world[world_w/2][world_h/2+1]
		w.id=.sand
		x=rand.float32()*2-1
		y=rand.float32()*2-1
		w.vector = {x,y}

		w=&world[world_w/2][world_h/2-1]
		w.id=.sand
		x=rand.float32()*2-1
		y=rand.float32()*2-1
		w.vector = {x,y}
	}

	if is_input_event(.enter,require_d = true,ignore_p = true){
		w:=&world[world_w/2][world_h/2]
		w.id=.water
		x:=rand.float32()*2-1
		y:=rand.float32()*2-1
		w.vector = {x,y}

		w=&world[world_w/2+1][world_h/2]
		w.id=.water
		x=rand.float32()*5-1
		y=rand.float32()*5-1
		w.vector = {x,y}
		
		w=&world[world_w/2-1][world_h/2]
		w.id=.water
		x=rand.float32()*2-1
		y=rand.float32()*2-1
		w.vector = {x,y}

		w=&world[world_w/2][world_h/2+1]
		w.id=.water
		x=rand.float32()*2-1
		y=rand.float32()*2-1
		w.vector = {x,y}

		w=&world[world_w/2][world_h/2-1]
		w.id=.water
		x=rand.float32()*2-1
		y=rand.float32()*2-1
		w.vector = {x,y}
	}
	// fmt.print(world[world_w/2][world_h/2],"\n")
	if g.time.frame_count >10 && g.time.frame_count < 12{ //! sadly must set fullscreen inside of game loop
		rl.ToggleFullscreen()
	}
}

draw :: proc() {
	// fmt.print("asdasdhkjasdf\nwaffles\nhi\n\n")
        
	rl.BeginDrawing()
	rl.ClearBackground(cast(rl.Color)bg_color)
	rl.BeginMode3D(g.cam)//g.cam
	// rl.BeginShaderMode(g.as.shaders.bace)


	rl.BeginBlendMode(.ADDITIVE)
	draw_particles()
	rl.EndBlendMode()

	rl.EndMode3D()

	rl.BeginMode2D(ui_camera())
	draw_world()
	rl.DrawTexturePro(buffer_image.texture,{0,0,cast(f32)world_w,cast(f32)world_h},{0,0,cast(f32)rl.GetScreenWidth(),cast(f32)rl.GetScreenHeight()},{0,0},0,{255,255,255,255})
	// rl.DrawRectangleRec({10,-100,200,200},{255,255,255,255})
	rl.EndMode2D()

	rl.DrawFPS(10,10)
	rl.EndDrawing()
}

cleanup_game::proc(){
	g.run = false

	clean_up_event_data()

}


ui_camera :: proc() -> rl.Camera2D {
	return {
		// zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
		offset = {},
		target = {},
		zoom = 1,
	}
}
