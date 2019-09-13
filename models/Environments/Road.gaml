/***
* Name: Road
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Road

import "Environment.gaml"

import "../Agents/Vehicle.gaml"

species road skills:[skill_road] parent:block {
	
	geometry display_shape;
	
	float span_between_lanes <- 2#m;
	
	list<geometry> lanes_shape;
	
	// ------ block ------ //
	
	bool contains_agent(agent the_agent){
		return all_agents contains the_agent;
	}
	
	list<road> neighboors {
		return (env.road_network in_edges_of source_node 
			+ env.road_network out_edges_of target_node) collect road(each);
	}
	
	// ------------------- //
	
	geometry compute_display_shape {
		
		list<float> vals <- list_with(lanes,0.0);
		float init;
		if(empty(linked_road)){
			if(lanes=1){
				return shape;
			} else {
				init <- -(span_between_lanes * (lanes-2) / 2 + (lanes mod 2 = 0 ? span_between_lanes/2 : 0));
			}
		} else {
			init <- span_between_lanes/2;
		}
		
		loop i from:0 to:lanes-1 {
			vals[i] <- init + span_between_lanes * i;
		}
		
		loop segs over:to_segments(shape) {
			float simple_angle <- first(segs.points) towards last(segs.points) + 90;
			loop val over:vals {
				lanes_shape <+ line(first(segs.points) + {cos(simple_angle) * val, sin(simple_angle) * val},
					last(segs.points) + {cos(simple_angle) * val, sin(simple_angle) * val});
			}
		}
		
		return union(lanes_shape);
	}
	
	aspect default {
		draw shape color:#black end_arrow:1;
	}
	
	aspect base {
		draw display_shape color:#black;
	}
}

species intersection skills:[skill_road_node] parent:block {
	bool inout <- false;
	
	bool contains_agent(agent the_agent){
		return self distance_to the_agent < 2#m;
	}
	
	list<intersection> neighboors {
		return remove_duplicates(roads_in collect intersection(road(each).source_node) 
			+ roads_out collect intersection(road(each).target_node));
	}
	
	aspect default {
		draw circle(0.5#m) color:inout?#green:#gray;
	}
}

species corridor skills:[pedestrian_road] parent:block {
	
	bool contains_agent(agent the_agent){
		return agents_on contains the_agent;
	}
	
	list<corridor> neighboors {
		return corridor where (each.shape.points contains_any shape.points);
	}
	
	aspect virtual {
		draw self.free_space color:#yellow;
	}
}