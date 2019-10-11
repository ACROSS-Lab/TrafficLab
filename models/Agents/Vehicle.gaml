/***
* Name: Vehicle
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Vehicle

import "People.gaml"
import "../Environments/Environment.gaml"
import "../AbstractLab.gaml"

species vehicle skills:[advanced_driving] {
	
	environment context;
	
	bool autonomous <- true;
	rgb color <- rnd_color(255);
	
	people driver;
	int capacity;
	
	float vehicle_width;
	
	float speed <- 50#km/#h;
	
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
	
	reflex move when:!autonomous and driver != nil {
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
		
		current_path <- compute_path(context.road_network, 
			context.road_network.vertices closest_to final_target,
			on_road::road closest_to self
		);
	}
	
	abort {
		if current_road != nil {
			ask road(current_road) {do unregister agent:myself;}
		}
	}
	
	// -------------------------------------------- //
	
	// Display purpose position on lanes
	point calcul_loc {
		if (current_road = nil) {
			return location;
		} else {
			float val <- first(road(current_road).shape.points) distance_to first(road(current_road).lanes_shape[current_lane].points);
			val <- on_linked_road ? val * - 1 : val;
			if (val = 0) {
				return location; 
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
	}
	
}

species car parent:vehicle { 
	
	init {
		//shape <- rectangle(vehicle_width,vehicle_length);
	}
	
	aspect default {
		draw rectangle(vehicle_width,vehicle_length) rotate:heading+90 color:color;
	}
	
	aspect base {
		draw rectangle(vehicle_width,vehicle_length) rotate:heading+90 color:color at:calcul_loc();
	}
	
	aspect big {
		draw rectangle(vehicle_width*3,vehicle_length*3) rotate:heading+90 color:color;
	}
	
}

species moto parent:vehicle {
	
}

species bus skills:[escape_publictransport_skill] parent:vehicle {
	// Quid of capture/release ?
	
	list<people> passengers;
	
	init {
		vehicle_width <- 3#m;
		vehicle_length <- 9#m;
		capacity <- 30;
		autonomous <- true;
		speed <- base_bus_speed * (1+rnd(1.0));
	}
	
	action define_target(point to_destination) {
		// If no next stop target or arrived at stop destination and on time to go for next one
		if next_stop = nil or (location = next_stop.location) { 
			do define_next_target;
		}
		
		// If there is next stop defined but no target
		if next_stop != nil and final_target = nil and is_time_to_go() {
				final_target <- next_stop;
				current_path <- compute_path(graph: context.road_network, target: next_stop);
				if(current_path = nil) { error "WARNING: nil current path : " + transport_line + ";" + location + ";" + next_stop; }
		}
		
	}
	
	aspect big {
		draw rectangle(vehicle_width*3,vehicle_length*3) rotate:heading+90 color:color;
	}
	
}
