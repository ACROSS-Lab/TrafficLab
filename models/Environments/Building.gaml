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
 * Building factory based on gridshape (@see GridEnvironment.gaml) <br/>
 * 
 * TODO : CHANGE BUILDING FACTORY NOT TO USE SPECIES (room & wall) AS LIST OF AGENT
 * 
 */
global {
	
	int base_id <- 1;
	float proba_expand_room parameter:true init:0.9 max:0.99 category:building;
	
	/*
	 * Simplest possible building : take a geometry turn in into a building with exit on each wall
	 */
	building create_simple_building(geometry building_shape) {
		
		create room with:[shape::building_shape,room_number::1] returns:r;
		if debug {write "Create a room";}
		
		ask to_segments(r[0].shape.contour) {
			create wall with:[line::self,shape::envelope(self buffer wall_thickness)] returns:w;
			ask r[0] {walls <- w;}
		}
		if debug {write "Create walls";}
		
		ask r[0] {ask walls {do create_door({-1,myself.room_number});}}
		if debug {write "Create doors";}
		
		return create_building();
	}
	
	/*
	 * Build a building from a gridshape
	 */
	building create_building_from_gs(gridshape gs) {
		list<room> the_rooms;
		
		int id <- base_id;
		bool available_cells <- true;
		
		float t <- machine_time;
		if debug {write "Create the first room to start building";}
		
		cell c <- gs.grid[{0,0}];
		c.value <- float(id);
		list<cell> current_room <- build_room(c);
		create room with:[shape::union(current_room),room_number::id]{ the_rooms <+ self; }
		if benchmark { write "Create first room ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		if debug {write "Expanding the building from neighbor to neighbor room, until no more space";}
		loop while:available_cells {
			c <- any(current_room accumulate (each.neighbors() where (each.value=0.0)));
			if c = nil {available_cells <- false;}
			else {
				id <- id + 1;
				c.value <- float(id);
				current_room <- build_room(c);
				create room with:[shape::union(current_room),room_number::id] { the_rooms <+ self; }
			}
		}
		
		if debug {write "Building contains "+length(the_rooms)+" rooms";}
		if benchmark { write "Create other rooms ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		ask room {
			loop g over:to_segments(shape.contour) { 
				if wall none_matches (each.line.points contains_all g.points) { 
					create wall with:[line::g,shape::envelope(g buffer wall_thickness)] { myself.walls <+ self; }
				} 
				else { walls <+ wall first_with (each.line.points contains_all g.points); }
			}
		}
		
		if room one_matches (empty(each.neighboors())) {
			error "There is room without any neighbors: \n"+sample(room where (empty(each.neighboors())));
		}
		if benchmark { write "Create the walls ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		if debug {write "Create doors !";} 
		int max_id <- max(room collect each.room_number);
		ask room {
			
			if room_number < max_id {
				room neigh <- neighboors() first_with (each.room_number = room_number+1);
				if neigh = nil {error "Only the last room should not have neighbor";}
				ask walls first_with (neigh.walls contains each) { do create_door({myself.room_number,neigh.room_number}); }
			}
			
			// CREATE MORE DOORS
			list<room> candidates <- neighboors() where not((each.walls accumulate each.members) contains_any 
				(walls accumulate each.members)
			);
			
			int nghb <- length(neighboors());
			loop while:nghb > 0 and not(candidates = nil or empty(candidates)) and flip(length(candidates)/nghb*0.5) {
				room c <- one_of(candidates);
				ask one_of(walls inter c.walls) { do create_door({myself.room_number,c.room_number}); }
				remove c from:candidates;
			}
			
		}
		
		if benchmark { write "Create the doors ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		return create_building();
	}
	
	/*
	 * Create a very simple building made of wall and doors
	 */
	building create_building_from_sh(geometry building_shape, int xn <- 2, int yn <- 1) {
		float t <- machine_time;	
		
		create room from:building_shape to_rectangles (xn,yn) { room_number <- int(self); }
		
		if benchmark { write "creating simple rooms ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		 
		ask room {
			loop g over:to_segments(shape.contour) {
				if wall none_matches (each.line.points contains_all g.points) {
					create wall with:[line::g,shape::envelope(g buffer wall_thickness)] {myself.walls <+ self;}
				} else {
					walls <+ wall first_with (each.line.points contains_all g.points);
				}
			}
		}
		
		if benchmark { write "creating simple walls ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		list<wall> connecting_walls;
		loop r over:room { 
			list cw <- (room - r) accumulate (each.walls inter r.walls);
			if cw != nil and not(empty(cw)) {connecting_walls <- cw;}
		}
		
		if connecting_walls = nil or empty(connecting_walls) {error "There must be at least one door";}
		else if debug {write "Creates door on "+sample(connecting_walls);}
		
		if benchmark { write "Find door walls ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		ask connecting_walls {
			list<room> cr <- room where (each.walls contains self); 
			if length(cr) > 2 {error  sample(self)+" cannot be connected to more that 2 room : "+sample(cr);}
			do create_door({cr[0].room_number,cr[1].room_number});
		} 
		
		if benchmark { write "Create simple doors ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		
		return create_building();
		
	}
	
	/*
	 * Create a room from the grid
	 */ 
	list<cell> build_room(cell starting_cell, float proba_expand <- proba_expand_room){
		
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
	 * Create a building from a previously created set of rooms
	 */
	building create_building {
		float t <- machine_time;
		
		create building returns:b {
			
			rooms <- list(room);
			list<geometry> lines <- generate_pedestrian_network([wall],room,true,false,3.0,0.1,true,0.1,0.0,0.0);
			if benchmark { write "Create "+sample(self)+" pedestrian network ["+string(machine_time-t)+"ms]"; t <- machine_time;}
			
			create corridor from: lines collect simplification(each, 0.01) with:[env::self] { do initialize distance:corridor_size obstacles:[wall]; }
			pedestrian_network <- as_edge_graph(corridor);
			if benchmark { write "init corridors ["+string(machine_time-t)+"]"; t <- machine_time;}	
			
		}
		
		if(reduced_angular_distance) {
			ask corridor { do build_exit_hub pedestrian_graph:env.pedestrian_network distance_between_targets: corridor_size/3; }
			if benchmark { write "Create hubs of corridors ["+string(machine_time-t)+"ms]"; t <- machine_time;}
		}
		
		
		return b[0];
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
		return (room - self) where (each.walls contains_any walls);
	}
	
	aspect default {
		draw shape color:color border:#transparent;
	}
	
}

species wall {
		
	geometry line;
		
	/*
	 *  Create a door in the_wall at given position {room1,room2}
	 */
	action create_door(point position){		
		point center <- any_location_in(line);
		float dist_to_corner <- min(line.points collect (each distance_to center));
		loop while: center = nil
			or (dist_to_corner < (door_width/2)+0.2#m) {
				
			if trace {write ""+self+" - "+center+" > "+dist_to_corner;}
				
			center <- any_location_in(line);
			dist_to_corner <- min(line.points collect (each distance_to center));	
		}
			
		if trace {write "Create a door on the wall "+sample(self);}
						
		geometry the_door <- envelope(((line * (door_width / line.perimeter)) translated_to center) buffer wall_thickness);
		
		shape <- shape - the_door;
				
		create door with:[shape::the_door,connection::position];
	}
		
	aspect default {
		draw shape color:#black;
	}
	
	/*
	 * 
	 */
	species door {
	
		point connection;
		aspect default {
			draw shape color:#red;
		}
	}

}	