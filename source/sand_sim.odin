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

cell_size:f32=1
world_w:int:320
world_h:int:180
world:[world_w][world_h]cell
buffer_image:rl.RenderTexture2D

air_resistence:f32=0.01
w_grav:[2]f32={0,-.02}
bg_color:[4]u8={10,10,10,255}

cell_d:[cell_ids]cell_data={
    .air={
        color={0, 0, 0, 0},
        density=0,
        friction=0,
        rebound=0,
        is_fluid=true,
        viscosity=1,
        
    },
    .sand={
        color={204, 193, 41, 255},
        density=1,
        friction=3,
        rebound=1,
        is_fluid=false,
        viscosity=1,
    },
    .water={
        color={20, 72, 204,255},
        density=.5,
        friction=.01,
        rebound=0,
        is_fluid=true,
        viscosity=0.1,
    },
    .lava={
        color={1,1,1,1},
        density=1,
        friction=.5,
        rebound=1,
        is_fluid=true,
        viscosity=0.4,
    },
}

cell_ids::enum{
    air,
    sand,
    water,
    lava,
}

cell_data::struct{
    color:[4]u8,
    density:f32,
    friction:f32,
    rebound:f32,
    is_fluid:bool,
    viscosity:f32,

}
cell::struct{
    id:cell_ids,
    pos:[2]f32,
    // velocity:f32,
    vector:[2]f32,
    last_f_swoped:uint,

}
draw_world::proc(){
    if g.time.is_60h_this_frame{
    rl.BeginTextureMode(buffer_image)
    rl.ClearBackground(cast(rl.Color)bg_color)
    for &row, x in &world{
        for &cell, y in &row{
            rl.DrawRectanglePro(
                rec={cast(f32)x*cell_size,cast(f32)y*cell_size,cell_size,cell_size},
                origin={0,0},
                rotation=0,
                color=cast(rl.Color)cell_d[cell.id].color
            )
        }
    }
    rl.EndTextureMode()
    }
}
update_world::proc(){
    if g.time.is_60h_this_frame{
        for &row, x in &world{
            for &cell, y in &row{
                cell_bacic_physics(&cell,{x,y})
                cell_move_logic(&cell,{x,y})
            }
        }
    }
}
cell_bacic_physics::proc(cell:^cell,pos:[2]int){
    if cell.id != .air{
        ground_pos:=pos+[2]int{cast(int)t_ceil(w_grav.x),cast(int)t_ceil(w_grav.y)}
        ground_cell:=get_cell(ground_pos)
        if ground_cell != nil{
            if should_sink(cell,ground_cell)||ground_cell.id == .air{
                cell.vector += w_grav*cell_d[cell.id].density
            }
        }
        cell.vector *= 1 - (air_resistence)
        cell.pos += cell.vector
    }
    t_ceil::proc(i:f32)->(out:f32){
        if i > 0{
            return math.ceil(i)
        }
        return math.floor(i)
    }
}
cell_move_logic::proc(cell:^cell,pos:[2]int,is_recersiv:bool=false){
    if cell.last_f_swoped != g.time.frame_count||is_recersiv{
        next_cell_pos:[2]int=[2]int{cast(int)cell.pos.x,cast(int)cell.pos.y}+pos
        if next_cell_pos != pos{
            dif_pos:[2]f32={0,0}
            next_cell_pos = pos
            if cell.pos.x > 1 {
                cell.pos.x -= 1
                next_cell_pos.x +=1
                dif_pos.x+=1
            }
            if cell.pos.x < 0 {
                cell.pos.x += 1
                next_cell_pos.x -=1
                dif_pos.x-=1
            }
            if cell.pos.y > 1 {
                cell.pos.y -= 1
                next_cell_pos.y +=1
                dif_pos.y+=1
            }
            if cell.pos.y < 0 {
                cell.pos.y += 1
                next_cell_pos.y -=1
                dif_pos.y-=1
            }
            next_cell:=get_cell(next_cell_pos)
            if next_cell != nil{
                if sould_sawp(cell,next_cell)||next_cell.id == .air{
                    swop_cell(cell, next_cell)
                    cell_move_logic(cell,next_cell_pos,is_recersiv = true)
                    if dif_pos.x != 0 {
                        cell.vector.x *= .50
                    }
                    if dif_pos.y != 0 {
                        cell.vector.y *= .50
                    }
                }else{
                    if dif_pos.x != 0 {
                        next_cell.vector.x += cell.vector.x
                        cell.vector.x = 0
                    }
                    if dif_pos.y != 0 {
                        next_cell.vector.y += cell.vector.y
                        cell.vector.y = 0
                    }
                }
            }else{
                cell.vector = {0,0}
            }
        }else if rand.float32() > cell_d[cell.id].viscosity&& math.abs(cell.vector.y)<.3&&math.abs(cell.vector.y)<.3{
            flow_pos:[2]int=pos+{rand.int_max(3)-1,0}
            flow_cell:=get_cell(flow_pos)
            if flow_cell != nil{
                if cell_d[flow_cell.id].is_fluid{
                    swop_cell(cell,flow_cell)
                }
            }
        }
    }
}
swop_cell::proc(cell_1:^cell,cell_2:^cell){
    cell_1.last_f_swoped=g.time.frame_count
    cell_2.last_f_swoped=g.time.frame_count
    t_cell:=cell_1^
    cell_1^=cell_2^
    cell_2^=t_cell
}
get_cell::proc(pos:[2]int)->(cell:^cell){
    if is_in_world(pos) {return &world[pos.x][pos.y]}
    return nil
}
is_in_world::proc(pos:[2]int)->(valid:bool){
    if pos.x > -1{
        if pos.x < world_w{
            if pos.y > -1{
                if pos.y < world_h{
                    return true
                }
            }
        }
    }
    return false
}
init_world::proc(){
    buffer_image = rl.LoadRenderTexture(cast(i32)world_w,cast(i32)world_h)
    fill_world(.air)
}
fill_world::proc(id:cell_ids){
        for &row, x in &world{
        for &cell, y in &row{
            cell.id = id
        }
    }
}
get_vilosity::proc(vec:[2]f32)->(vilosity:f32){
    return math.sqrt(math.abs((vec.x*vec.x)+(vec.y*vec.y)))
}
get_pow::proc(vec:[2]f32,density:f32)->(pow:f32){
    return get_vilosity(vec)*pow
}
get_cell_pow::proc( cell:^cell)->(pow:f32){
    vec:[2]f32=cell.vector
    density:f32= cell_d[cell.id].density*2
    if cell.id == .air{
        return 0
    }
    return get_vilosity(vec)*density
}


sould_sawp::proc(cell_1:^cell,cell_2:^cell)->(swap:bool){
    c1_p:=get_cell_pow(cell_1)
    c2_p:=get_cell_pow(cell_2)*cell_d[cell_2.id].friction
                      
    if c1_p>c2_p{
        return true
    }
    return false
}
should_sink::proc(cell_1:^cell,cell_2:^cell)->(sink:bool){
    c1_sink_v:=cell_d[cell_1.id].density
    c2_sink_v:=cell_d[cell_1.id].density*cell_d[cell_1.id].friction
    if c1_sink_v < c2_sink_v{
        return true
    }
    return false
}