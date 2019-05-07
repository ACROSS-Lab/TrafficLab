/***
* Name: pedestrian
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pedestrian

import "Building.gaml"

species people virtual:true skills:[moving] {
	
	building current_building;
	rgb color <- rgb(#green,rnd(1.0));
	rgb side_color <- rnd_color(255);
	string the_aspect;
	
	bool arrive <- false;
	point target <- nil;
	float speed <- 3 #km/#h;
	
	reflex here_we_go_again when:arrive {
		arrive <- false;
		color <- rgb(#green,rnd(1.0));
	}
	
	room get_current_room {
		if(current_building = nil){
			return nil;
		}
		return current_building.rooms first_with (self overlaps each);
	}
	
	bool arrived_at_destination virtual:true {}
	
}

species simple_people parent:people skills:[pedestrian] {
	
	reflex move when:not(arrive) {
		
		if(target = nil){
			target <- current_building=nil ? any_location_in(world) : any_location_in(one_of(room - get_current_room()));
		}
		
		do walk target:target; //bounds:current_building.get_free_space();
		
		if(arrived_at_destination()) {}
		
	}
	
	bool arrived_at_destination {
		if(location distance_to target < 1#m){
			arrive <- true;
			target <- nil;
			return true;
		}
		return false;
	}
	
	aspect default {
		switch the_aspect {
			match "destination" {
				draw triangle(shoulder_length) rotate: heading + 90 color:color;
				draw "A"+int(self) at:self.location+{0.5,0.5,0} color:color;
				draw cross(0.1,0.1) at:target color:color;
				draw "DA"+int(self) at:target+{0.5,0.5,0} color:color;
			}
			default {
				draw triangle(1) rotate: heading + 90 color:color;
			}
		}
	}
	
}

species advanced_people parent:people skills:[escape_pedestrian] {
	
	float speed <- 1#m/#s;
	graph pedestrian_network;
	
	reflex move when:not(arrive) {
		 
		if(target = nil){ 
			color <- rgb(#blue,rnd(1.0));
			target <- current_building=nil ? any_location_in(world) : any_location_in(one_of(room - get_current_room()));
			final_target <- target;
			do compute_virtual_path pedestrian_graph:pedestrian_network final_target: final_target ;		
		}
		
		if(arrived_at_destination()){ } 
		else if(length(targets) - current_index = 1){
			do goto target:target;
		} else {
			do walk;
		}
		
	}
	
	bool arrived_at_destination {
		if(location distance_to target < 1#m){
			arrive <- true;
			target <- nil;
			final_target <- nil;
			color <- #red;
			return true;
		} 
		return false;
	}
	
	aspect default {
		switch the_aspect {
			match "path" {
				draw triangle(shoulder_length) rotate: heading + 90 color:side_color;
				draw "A"+int(self) at:self.location+{0.5,0.5,0} color:side_color;
				loop l over:current_path.segments {
					draw l color:side_color;
				}
				draw cross(0.1,0.1) at:current_target color:#red;
				draw ""+int(self) at:current_target+{0.5,0.5,0} color:#red;
			}
			match "destination" {
				draw triangle(shoulder_length) rotate: heading + 90 color:color;
				draw "A"+int(self) at:self.location+{0.5,0.5,0} color:color;
				draw cross(0.1,0.1) at:target color:color;
				draw "DA"+int(self) at:target+{0.5,0.5,0} color:#green;
			}
			default {
				draw triangle(1) rotate: heading + 90 color:color;
			}
		}
	}
	
} 

