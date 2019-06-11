/***
* Name: Vehicle
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Vehicle

import "People.gaml"
import "../Environments/Environment.gaml"

species vehicle skills:[advanced_driving] {
	
	environment context;
	
	bool autonomous <- true;
	rgb color <- rnd_color(255);
	
	people driver;
	int capacity;
	
	float speed <- 50#km/#h;
	
	init {
		
		
		max_speed <- 80 #km / #h;
		vehicle_length <- 5.0 #m;
		right_side_driving <- true;
		proba_lane_change_up <- 0.1 + (rnd(500) / 500);
		proba_lane_change_down <- 0.5 + (rnd(500) / 500);
		safety_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
		proba_respect_priorities <- 1.0 - rnd(200 / 1000);
		proba_respect_stops <- [1.0];
		proba_block_node <- 0.0;
		proba_use_linked_road <- 0.0;
		max_acceleration <- 5 / 3.6;
		speed_coeff <- 1.2 - (rnd(400) / 1000);
		
		
	}
	
	// ----------- CAPTION PASSENGER ------------ //
	
	species passenger parent:people schedules:[] { 
		bool arrived_at_destination {
			if(host distance_to target < 1#m){
				return true;
			}
			return false;
		}
	}
	
	bool capture_people(people the_people, bool is_driver){
		if(length(members) < capacity){
			capture the_people as:passenger returns:the_passengers;
			if(not(autonomous) and (is_driver or empty(self.members))){
				driver <- the_passengers[0];
			}
			return true;
		}
		return false;
	}
	
	// ------------------------------------------ //
	
	reflex autonomous_move when:autonomous {
		
		if(final_target = nil){
			do define_target(context.any_destination(self));
		}
		
		do drive;
	}
	
	reflex move when:driver != nil {
		if(final_target = nil){
			do define_target(driver.target);
		}
		
		do drive;
		
		if(driver.arrived_at_destination()){
			release target:members as:people in:world;
		}
	}
	
	action define_target(point to_destination){
		final_target <- to_destination;
		current_path <- compute_path(context.road_network, context.road_network.vertices closest_to final_target);
	}
	
}

species car parent:vehicle { 
	
	init {
		//shape <- rectangle(1.5#m,4#m);
	}
	
	aspect default {
		//draw shape color:color rotate:heading; // use heading cause simulation to stop
		draw rectangle(1.5#m,4#m) rotate:heading+90 color:color;
	}
	
}

species moto parent:vehicle {
	
}

species bus skills:[escape_publictransport_skill] parent:vehicle {
	
}
