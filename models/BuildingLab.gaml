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
	
	bool debug_mode <- false parameter:true category:"display";
	
	// Building parameters
	string building_type parameter:true among:["simple","complex"] init:"complex" category:building;
	float door_width parameter:true init:1.2#m min:0.5#m max:10#m category:building;
	float wall_thickness <- 10#cm;
	float proba_expand_room parameter:true init:0.9 max:0.99 category:building;
	
	float world_size <- 100#m;
	float step <- 1#s/10;
	
	geometry shape <- square(world_size);
	
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
	
	action create_simple_building(geometry building_shape) {
		int room_height <- one_of(2,3,5);
		
		point pr_ul <- {0,building_shape.height/2+room_height*2};
		point pr_br <- {building_shape.width, building_shape.height/2-room_height*2};
		geometry s_building <- rectangle(pr_ul,pr_br);
		
		create room from:s_building to_rectangles (2,1){
			room_number <- int(self);
		}
		
		geometry door_wall <- intersection(room[0],room[1]);
		
		door the_door <- create_door(door_wall, {0,1});
		
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
		
		create building {
			
			rooms <- list(room);
			list<geometry> lines <- generate_pedestrian_network([wall],room,true,false,3.0,0.1,true,0.0,0.0,0.0);
			
			create corridor from: lines collect simplification(each, 0.01) { do initialize distance:corridor_size obstacles:[wall]; }
			pedestrian_network <- as_edge_graph(corridor);	
			
		}
		
	}
	
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
			create room with:[shape::union(current_room),room_number::id]{ the_rooms <+ self; }
			
			list<room_cell> nghbs <- current_room accumulate (each.neighbors where (each.grid_value = 0.0));
			//s_cell <- one_of(nghbs);
			s_cell <- nghbs with_max_of (length(each.neighbors inter nghbs));
			if(s_cell = nil){ 
				available_cells <- false;
			} else {
				id <- id+1;
				s_cell.grid_value <- float(id);
				room_cell c_cell <- one_of(s_cell.neighbors where (current_room contains each));
				
				do create_door(s_cell.shape.contour intersection c_cell.shape.contour, {id-1,id});

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
			available_nghbr_rn <- remove_duplicates(available_nghbr_rn) - r.room_number - nghbr_rn - 0;
			
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
	
	// Create a door in the_wall at given position {room1,room2}
	door create_door(geometry the_wall, point position){
		
		point center;
		loop while:center=nil 
			or (center distance_to world.shape.contour < (door_width/2)+0.2#m) 
			or (min(the_wall.points collect (each distance_to center)) < (door_width/2)+0.2#m) {
			center <- any_location_in(the_wall);	
		}
						
		geometry the_door <- envelope(translated_to(the_wall * (door_width / the_wall.perimeter), center) buffer wall_thickness);
				
		create door with:[shape::the_door,connection::position] returns:the_doors;
		return first(the_doors);
	}
		
}


grid room_cell cell_width:4#m cell_height:4#m neighbors:4 {
	float grid_value <- 0.0;
}


experiment BuildingSetup parent:lab {

	output {
		display "Building" {
			
			species room;
			species door;
			species wall;
			agents value:agents of_generic_species people;
		}
	}
}
	


