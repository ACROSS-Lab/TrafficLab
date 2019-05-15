/***
* Name: pedestrian
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model pedestrian

import "../Environments/Environment.gaml"

species people virtual:true skills:[moving] {
	
	environment current_environment;
	
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
	
	block get_current_place {
		if(current_environment = nil){
			return nil;
		}
		return current_environment.current_block(self);
	}
	
	bool arrived_at_destination virtual:true {}
	
}

species simple_people parent:people skills:[pedestrian] {
	
	reflex move when:not(arrive) {
		
		if(target = nil){
			target <- current_environment.any_location(self);
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
	
	reflex move when:not(arrive) {
		if(target = nil){ 
			color <- rgb(#blue,rnd(1.0));
			target <- current_environment.any_location(self);
			final_target <- target;
			do compute_virtual_path pedestrian_graph:current_environment.pedestrian_network  final_target: final_target ;	
		}
		if(arrived_at_destination()){ 
			
		} else {
			
			do walk;
		}
		
	}
	
	bool arrived_at_destination {
		if(current_target = nil){
			arrive <- true;
			target <- nil;
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
				if (final_target != nil) {draw cross(0.1,0.1) at:final_target color:#green;}
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

