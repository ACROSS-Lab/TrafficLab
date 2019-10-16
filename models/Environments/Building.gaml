/***
* Name: Environment
* Author: kevinchapuis
* Description: 
* Tags: environment, building
***/

model Building

import "Environment.gaml"
import "../Utils/GridEnvironment.gaml"

/*
 * Building factory based on gridshape (@see GridEnvironment.gaml)
 */
global {
	
	int base_id <- 1;
	float proba_expand_room <- 0.1;
	
	/*
	 * Build a building from a gridshape
	 */
	building create_building(gridshape gs) {
		list<room> the_rooms;
		
		int id <- base_id;
		bool available_cells <- true;
		
		if debug_mode {write "Create the first room to start building";}
		cell c <- gs.grid[{0,0}];
		c.value <- float(id);
		list<cell> current_room <- create_room(c);
		create room with:[shape::union(current_room),room_number::id]{ the_rooms <+ self; }
		
		if debug_mode {write "Expanding the building from neighbor to neighbor room, until no more space";}
		loop while:available_cells {
			room previous_room <- room first_with (each.room_number = id);
			c <- (cell where (each.value = 0.0)) with_max_of (each.neighbors() count (each.value = float(id)));
			if c = nil {available_cells <- false;}
			else {
				id <- id + 1;
				c.value <- float(id);
				current_room <- create_room(c);
				create room with:[shape::union(current_room),room_number::id] { the_rooms <+ self; }
				geometry connecting_wall <- c.shape inter any(c.neighbors() where (each.value=previous_room.room_number)).shape;
				//do create_door(connecting_wall, {last(the_rooms).room_number,previous_room.room_number});
			}
		}
		
		if debug_mode {write "Building contains "+length(the_rooms)+" rooms";}
		
		if debug_mode {write "Create walls !";}
		list<wall> walls_done;
		ask room {
			list<wall> wd;
			list<geometry> walls_to_be_done;
			loop g over:to_segments(shape.contour) { 
				if walls_done none_matches (each.shape.points contains_all g.points) { walls_to_be_done <+ g; } 
				else { wd <+ walls_done first_with (each.shape.points contains_all g.points); }
			}
			
			write "[building.gaml]  : "+sample(walls_to_be_done);
			write "[building.gaml]  : "+sample(wd);
			
			loop w over:walls_to_be_done { 
				create wall with:[shape::w] {
					write "[building.gaml]  : "+sample(self); 
					walls_done <+ self;
					myself.walls <+ self;
				}
			}
			if not empty(wd) {walls <+ wd;}
		}
		
		if debug_mode {write "Create doors !";} 
		int max_id <- max(room collect each.room_number);
		ask room {
			
			if room_number < max_id {
				room neigh <- neighboors() first_with (each.room_number = room_number+1);
				ask one_of (walls where (neigh.walls contains each)) {
					door connecting_door <- world.create_door(self,{myself.room_number,neigh.room_number});
				}
			}
			
			// CREATE MORE DOORS
			list<room> candidates <- neighboors() where not((each.walls accumulate each.members) contains_any 
				(walls accumulate each.members)
			);
			
			write "[building.gaml] : "+sample(candidates);
			write "[building.gaml] : "+sample(neighboors());
			write "[building.gaml] : "+sample(walls);
			write "[building.gaml] : "+sample(neighboors() accumulate each.walls);
			
			/* 
			write "[building.gaml] : "+neighboors() accumulate (each.walls accumulate each.members);
			write "[building.gaml] : "+walls accumulate each.members;  
			* 
			*/
			
			loop while:not(candidates = nil) and flip(length(candidates)/length(neighboors())) {
				room c <- one_of(candidates);
				ask one_of(walls inter c.walls) {
					door connecting_door <- world.create_door(self, {myself.room_number,c.room_number});
				}
				
			}
			
		}
		
		create building with:[rooms::the_rooms] returns:b {
			list<geometry> lines <- generate_pedestrian_network([wall],room,true,false,3.0,0.1,true,0.0,0.0,0.0);
			
			create corridor from: lines collect simplification(each, 0.01) { do initialize distance:corridor_size obstacles:[wall]; }
			pedestrian_network <- as_edge_graph(corridor);
		}
		
		return b[0];
	}
	
	/*
	 * Create a very simple building made of wall and doors
	 */
	action create_simple_building(geometry building_shape) {
				
		create room from:building_shape to_rectangles (int(building_shape.height/rnd(3,7)#m),int(building_shape.width/rnd(3,7)#m)) {
			room_number <- int(self);
		}
		/* 
		geometry door_wall <- intersection(room[0],room[1]);
		
		door the_door <- create_door(door_wall, {0,1});
		* 
		
		
		loop r over:room {
			loop g over:to_segments(r.shape.contour){
				geometry w <- envelope(g buffer 10#cm) ;
				bool has_door <- false;
				if(g overlaps the_door){
					w <- w - the_door;
					has_door <- true;	
				}
				
				create wall with:[shape::w] returns:the_wall{
					if(has_door){ doors <+ the_door;}
				}
				
				r.walls <<+ the_wall;
			}
		}
		* 
		*/
		
		create building {
			
			rooms <- list(room);
			list<geometry> lines <- generate_pedestrian_network([wall],room,true,false,3.0,0.1,true,0.0,0.0,0.0);
			
			create corridor from: lines collect simplification(each, 0.01) { do initialize distance:corridor_size obstacles:[wall]; }
			pedestrian_network <- as_edge_graph(corridor);	
			
		}
		
	}
	
	/*
	 * Create a room from the grid
	 */ 
	list<cell> create_room(cell starting_cell, float proba_expand <- proba_expand_room){
		
		list<cell> the_room <- [starting_cell];
		float id <- starting_cell.value;
		loop while:length(the_room) < 2 or flip(proba_expand){
			cell next_cell <- one_of(last(the_room).neighbors() where (each.value=0.0));
			if(next_cell = nil){ break; }
			the_room <+ next_cell;
			next_cell.value <- id;
		}
		return the_room;
		
	}
	
	/*
	 *  Create a door in the_wall at given position {room1,room2}
	 */
	action create_door(wall the_wall, point position){		
		point center <- any_location_in(the_wall);
		float dist_to_corner <- min(the_wall.shape.points collect (each distance_to center));
		loop while: center = nil
			or (dist_to_corner < (door_width/2)+0.2#m) {
				
			if debug_mode {write ""+the_wall+" - "+center+" > "+dist_to_corner;}
				
			center <- any_location_in(the_wall);
			dist_to_corner <- min(the_wall.shape.points collect (each distance_to center));	
		}
			
		if debug_mode {write "Create a door on the wall "+the_wall;}
						
		geometry the_door <- envelope(((the_wall.shape * (door_width / the_wall.shape.perimeter)) translated_to center) buffer wall_thickness);
				
		ask the_wall {create door with:[shape::the_door,connection::position];}
	}
	
}

species building parent:environment {
		
	list<room> rooms;
	geometry the_free_space <- nil;
	
	geometry get_free_space {
		
		if(the_free_space = nil){
			the_free_space <- union(room collect each.shape);
			the_free_space <- the_free_space - union(union(room accumulate each.walls));
		}
		return the_free_space;
	}
	
	list<room> get_blocks {
		return rooms;
	}
	
	room current_block(agent the_agent) {
		return rooms first_with (each overlaps the_agent);
	}
	
	point any_location(agent the_agent) {
		return any_location_in(any(rooms));
	}
	
	point any_destination(agent the_agent) {
		return any_location_in(any(rooms-current_block(the_agent)));
	}
	
}

species room parent:block {

	list<wall> walls;
	int room_number;
	
	rgb color <- #gray; //rgb(rnd_color(255), 0.2);
	
	bool contains_agent(agent the_agent) {
		return self overlaps the_agent;
	}
	
	list<room> neighboors {
		return room where (each.walls contains_any walls);
	}
	
	aspect default {
		draw shape color:color border:#transparent;
	}
	
}

species wall {
		
	aspect default {
		draw shape color:#black;
	}
	
	species door {
	
		point connection;
		aspect default {
			draw shape color:#red;
		}
	}

}	