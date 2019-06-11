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
	
	graph road_network; 
	
	int nb_vehicles parameter:true init:10;
	
	init {
		
		float mid_x <- shape.width/2;
		float mid_y <- shape.height/2;
		
		geometry l1 <- line({mid_x,shape.height},{mid_x,0});
		geometry l2 <- line({0,mid_y},{shape.width,mid_y});
		
		create virtual_lane from:split_lines([l1,l2]) with:[road_width::rnd(2.0,5.0)];
		
		/* 
		loop p over:as_edge_graph(road).vertices collect each.location {
			create intersection with:[shape::p] {
				if(p.x=0 or p.x=world.shape.width or p.y=0 or p.y=world.shape.height) {
					inout <- true;	
				}
			}
		}
		* 
		*/
		
		loop r over:virtual_lane {
			create virtual_lane {
				road_width <- r.road_width;
				shape <- polyline(reverse(r.shape.points));
			}
		}
		
		road_network <- as_edge_graph(virtual_lane);
		
		create virtual_lane_vehicle number:nb_vehicles {
			current_lane <- any(virtual_lane);
			location <- any_location_in(current_lane);
			sub_target <- last(current_lane.shape.points);
			transport_system <- road_network;
		}
		
	}
	
}

experiment vl { //parent:vehicle_lab {
	output {
		display virual_lanes {
			species virtual_lane transparency:0.4;
			species virtual_lane_vehicle;
			graphics network {
				loop v over:road_network.vertices {
					draw square(1) at:v color:#green;
				}
			}
		}
	}
}

