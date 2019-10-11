/***
* Name: SimpleBuildingSetup
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SimpleBuildingSetup

import "Agents/People.gaml"
import "Environments/Road.gaml"
import "Environments/Building.gaml"
import "AbstractLab.gaml"

global {
	
	bool debug_mode <- true parameter:true category:"display";
	
	// Building parameters
	string building_type parameter:true among:["simple","complex"] init:"complex" category:building;
	float proba_expand_room parameter:true init:0.9 max:0.99 category:building;
	
	float step <- 1#s/10;
	
	geometry shape <- square(int(world_size.x+world_size.y/2));
	
	init{
		
		switch building_type {
			match "complex" {
				do create_building();
			} 
			match "simple" {
				do create_simple_building(world.shape);
			}
		}
		
		env <- building[0];
		
		ask people {
			switch species_of(self) {
				match simple_people {
					simple_people(self).obstacle_species << wall;
				}
				match advanced_people {
					advanced_people(self).obstacle_species << wall;
				} 
			}
		}
		
	}
	
	/*
	 * Create a building based on a grid topology
	 */
	action create_building {
		
		list<room> the_rooms;
		
		int id <- 1;
		bool available_cells <- true;
		
		room_cell s_cell <- room_cell[int(max(room_cell collect (each.grid_x))/2), int(max(room_cell collect (each.grid_y))/2)];
		s_cell.grid_value <- float(id);
		list<room_cell> current_room;
		
		if(debug_mode){write "Create the room path with single doors";}
		loop while:available_cells {
			current_room <- create_room(s_cell);
			if debug_mode {write "Create room "+id+" with size : "+current_room;}
			create room with:[shape::union(current_room) with_precision 1#cm,room_number::id]{ the_rooms <+ self; }
			
			list<room_cell> nghbs <- current_room accumulate (each.neighbors where (each.grid_value = 0.0));
			//s_cell <- one_of(nghbs);
			s_cell <- nghbs with_max_of (each.neighbors count (each.grid_value = id));
			if(s_cell = nil){ 
				available_cells <- false;
			} else {
				room_cell c_cell <- one_of(s_cell.neighbors where (each.grid_value = id));
				if c_cell = nil {error "not possible";}
				id <- id+1;
				s_cell.grid_value <- float(id);
				
				list p_wall;
				loop p over:s_cell.shape.points {
					if c_cell.shape.points one_matches ((each with_precision 3) = (p with_precision 3)) {
						p_wall <+ p;
					}
				}
				
				geometry the_wall <- line(remove_duplicates(p_wall));
				
				if length(the_wall.points) < 2 {
					write sample(s_cell)+" : "+sample(s_cell.neighbors collect int(each));
					write sample(c_cell)+" : "+sample(c_cell.neighbors collect int(each));
					write sample(p_wall); 
					write sample(s_cell.shape.points);
					write sample(c_cell.shape.points);
					error sample(the_wall)+" must be a line";
				} else {
					do create_door(the_wall, {id-1,id});
				}
				
			}
			
		}
		if(debug_mode) {write "End creating "+length(the_rooms)+" rooms";}
		
		
		// Add new doors to avoid having only one path between all the rooms
		if(debug_mode){write "Add new doors to avoid having only one path between all the rooms";}
		loop r over:room {
			
			list<door> doors <- door where (each.connection.x = r.room_number or each.connection.y = r.room_number);
			list<int> nghbr_rn <- remove_duplicates(doors accumulate int(each.connection.x) 
				+ doors accumulate int(each.connection.y) - r.room_number);
			
			list<int> available_nghbr_rn;
			loop c over:room_cell where (each.grid_value = float(r.room_number)){
				available_nghbr_rn <<+ c.neighbors accumulate (int(each.grid_value)); 
			} 
			
			int nb_n <- length(available_nghbr_rn) -  1;
			available_nghbr_rn <- remove_duplicates(available_nghbr_rn) - r.room_number - nghbr_rn;
			
			loop while:length(available_nghbr_rn) > 1 and flip(1.0 - (length(doors) / nb_n)) {
				room new_ngb <- one_of(room where (available_nghbr_rn contains each.room_number));
				
				available_nghbr_rn >- new_ngb.room_number;
				geometry the_wall <- one_of(to_segments(r.shape.contour intersection new_ngb.shape.contour));
				doors <+ create_door(the_wall, {r.room_number,new_ngb.room_number});
			}
			
		}
		
		// Create the walls removing doors from room contour
		if(debug_mode){write "Create walls between rooms";}
		loop r over:room {
			
			list<door> the_doors <- door where (each.connection.x =  r.room_number or each.connection.y = r.room_number);
			geometry doors <- union(the_doors);
						
			loop g over:to_segments(r.shape.contour){
				geometry w <- envelope(g buffer 10#cm) - doors;
				create wall with:[shape::w,doors::the_doors] returns:the_wall;
				r.walls <<+ the_wall;
			}
			
		}
		
		// Create the building from the rooms
		if(debug_mode){write "Create the building from the rooms, with inner virtual pedestrian network";}
		create building {
			
			rooms <- the_rooms;
			
			list<geometry> lines <- generate_pedestrian_network([wall],room,true,false,0.5,0.1,true,0.0,0.0,0.0);
			create corridor from: lines { do initialize distance:corridor_size obstacles:[wall]; }
			pedestrian_network <- as_edge_graph(corridor);	
			
		}
		
	}
	
	// Create a room from the grid
	list<room_cell> create_room(room_cell starting_cell){
		
		list<room_cell> the_room <- [starting_cell];
		float id <- starting_cell.grid_value;
		loop while:length(the_room) < 2 or flip(proba_expand_room){
			room_cell next_cell <- one_of(last(the_room).neighbors where (each.grid_value=0.0));
			if(next_cell = nil){ break; }
			the_room <+ next_cell;
			next_cell.grid_value <- id;
		}
		return the_room;
	}
		
}


grid room_cell cell_width:4#m cell_height:4#m neighbors:4 {
	float grid_value <- 0.0;
}


experiment BuildingSetup parent:lab {

	parameter "Door width" var:door_width min:0.5#m max:10#m category:building;

	output {
		display "Building" {
			
			species room;
			species door;
			species wall;
			agents value:agents of_generic_species people;
		}
	}
}
	


