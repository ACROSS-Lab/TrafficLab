/***
* Name: VirtualLaneCrossection
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model VirtualLaneCrossection

import "../AbstractLab.gaml"
import "VirtualLane.gaml"

global {
	
	bool log <- true;
	
	graph road_network; 
	
	int nb_vehicles parameter:true init:10;
	
	init {
		
		float mid_x <- shape.width/2;
		float mid_y <- shape.height/2;
		
		geometry l1 <- line({mid_x,shape.height},{mid_x,0});
		geometry l2 <- line({0,mid_y},{shape.width,mid_y});
		
		create virtual_road from:split_lines([l1,l2]) with:[road_width::rnd(2.0,5.0)];
		
		loop r over:virtual_road {
			create virtual_road with:[
				shape::polyline(reverse(r.shape.points)),
				road_width::r.road_width
			];
		}
		
		road_network <- as_edge_graph(virtual_road);
		
		create virtual_lane_vehicle number:nb_vehicles {
			current_road <- any(virtual_road);
			current_road.registered_vehicles <+ self;
			location <- any_location_in(current_road);
			transport_system <- road_network;
		}
		
	}
	
}

experiment vl { //parent:vehicle_lab {

	float seed <- 123;

	output {
		display virual_lanes {
			species virtual_road transparency:0.4;
			species virtual_lane_vehicle;
			graphics network {
				loop v over:road_network.vertices {
					draw square(1) at:v color:#green;
				}
			}
		}
	}
}

