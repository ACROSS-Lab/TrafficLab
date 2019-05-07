/***
* Name: Road
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Road

species road skills:[skill_road] {
	
	init {
		
		maxspeed <- 50#km/#h;
		
	}
	
	aspect default {
		draw shape color:#black; // end_arrow:1;
	}
}

species intersection skills:[skill_road_node] {
	bool inout <- false;
	
	aspect default {
		draw circle(0.5#m) color:inout?#green:#gray;
	}
}

species pedestrian_path skills:[pedestrian_road] {
	aspect virtual {
		draw self.free_space color:#yellow;
	}
}