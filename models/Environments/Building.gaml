/***
* Name: Environment
* Author: kevinchapuis
* Description: 
* Tags: environment, building
***/

model Building

import "Environment.gaml"

species building parent:environment {
	
	init {
		
		// Should init building here
		
	}
		
	list<room> rooms;
	geometry the_free_space <- nil;
	
	geometry get_free_space {
		
		if(the_free_space = nil){
			the_free_space <- union(room collect each.shape);
			the_free_space <- the_free_space - union(union(room accumulate each.walls));
		}
		return the_free_space;
	}
	
	// ----------------------------------------- //
	
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
	
	// ------------------------------------------ //
	
	// 	  PUT HERE ACTIONS TO CREATE BUILDING
	
	// ------------------------------------------ //
	
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