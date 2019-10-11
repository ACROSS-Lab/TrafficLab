/***
* Name: Environment
* Author: kevinchapuis
* Description: 
* Tags: environment, building
***/

model Building

import "Environment.gaml"

global {
	
	/*
	 * Create a very simple building made of wall and doors
	 */
	action create_simple_building(geometry building_shape) {
		int room_height <- one_of(2,3,5);
		
		/* 
		point pr_ul <- {0,building_shape.height/2+room_height*2};
		point pr_br <- {building_shape.width, building_shape.height/2-room_height*2};
		geometry s_building <- rectangle(pr_ul,pr_br);
		* 
		*/
		
		// TODO : define a number of x and y rectangle tacking into account
		// the length and width of building_shape
		
		create room from:building_shape to_rectangles (2,1) {
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
	
	/*
	 *  Create a door in the_wall at given position {room1,room2}
	 */
	door create_door(geometry the_wall, point position){		
		point center <- any_location_in(the_wall);
		float dist_to_corner <- min(the_wall.points collect (each distance_to center));
		loop while: center = nil
			or (dist_to_corner < (door_width/2)+0.2#m) {
				
			if debug_mode {write ""+the_wall+" - "+center+" > "+dist_to_corner;}
				
			center <- any_location_in(the_wall);
			dist_to_corner <- min(the_wall.points collect (each distance_to center));	
		}
			
		if debug_mode {write "Create a door on the wall "+the_wall;}
						
		geometry the_door <- envelope(translated_to(the_wall * (door_width / the_wall.perimeter), center) buffer wall_thickness);
				
		create door with:[shape::the_door,connection::position] returns:the_doors;
		return first(the_doors);
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

	int room_number;
	list<wall> walls;
	
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
	
	list<door> doors;
	
	aspect default {
		draw shape color:#black;
	}
}

species door {
	point connection;
	aspect default {
		draw shape color:#red;
	}
}