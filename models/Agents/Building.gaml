/***
* Name: Environment
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Building

species building {
	
	graph network;
		
	list<room> rooms;
	geometry the_free_space <- nil;
	
	geometry get_free_space {
		
		if(the_free_space = nil){
			the_free_space <- union(room collect each.shape);
			the_free_space <- the_free_space - union(union(room accumulate each.walls));
		}
		return the_free_space;
	}
	
}

species room {

	int room_number;
	list<wall> walls;
	
	rgb color <- #gray; //rgb(rnd_color(255), 0.2);
	
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

species pedestrian_path skills:[pedestrian_road] {
	aspect virtual {
		draw shape color:#black;
		loop pt over: shape.points {
			draw square(0.1) color: #blue at: pt;
		}
	}
}