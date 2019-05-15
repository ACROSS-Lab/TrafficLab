/***
* Name: Road
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Road

import "Environment.gaml"

species road skills:[skill_road] parent:block {
	
	init {
		
		maxspeed <- 50#km/#h;
		
	}
	
	bool contains_agent(agent the_agent){
		return agents_on contains the_agent;
	}
	
	aspect default {
		draw shape color:#black end_arrow:1;
	}
}

species intersection skills:[skill_road_node] parent:block {
	bool inout <- false;
	
	bool contains_agent(agent the_agent){
		return self distance_to the_agent < 2#m;
	}
	
	aspect default {
		draw circle(0.5#m) color:inout?#green:#gray;
	}
}

species corridor skills:[pedestrian_road] parent:block {
	
	bool contains_agent(agent the_agent){
		return agents_on contains the_agent;
	}
	
	aspect virtual {
		draw self.free_space color:#yellow;
	}
}