/***
* Name: CrossRoadSetup
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CrossRoadSetup

import "Environments/Road.gaml"
import "Environments/Ward.gaml"
import "Agents/Vehicle.gaml"
import "AbstractLab.gaml"

global {
	
	bool debug_mode <- true; 
	
	string setup parameter:true init:"simple" among:["simple", "multiple", "complex"] category:"Transport system";
	int number_of_intersections parameter:true init:20 min:5 category:"Transport system";
	
	int number_of_vehicles parameter:true init:20 min:2 max:100 category:vehicle;
	bool autonomous_vehicles init:true category:vehicle;
	
	// Multiple args
	int x_lain_nb <- 8;
	int y_lain_nb <- 4;
	// Complex args
	float scale_free_proba;
	// Two way road probability
	float two_way_road_proba <- 1.0;
	
	init {
		
		list<geometry> lines;
		
		create ward with:[shape::world];
		env <- ward[0];
		
		switch setup {
			match "simple" {lines <- simple_setup();}
			match "multiple" {lines <- multiple_setup();}
			match "complex" {lines <- complex_setup();}
		}
		
		create road from:split_lines(lines) with:[lanes::2,maxspeed::50#km/#h];
		
		loop p over:as_edge_graph(road).vertices collect each.location {
			create intersection with:[shape::p] {
				if(p.x=0 or p.x=world.shape.width or p.y=0 or p.y=world.shape.height) {
					inout <- true;	
				}
			}
		}
		
		// Two way road
		loop r over:road {
			if(r.shape.points one_matches ((intersection collect each.location) contains (each))
				or flip(two_way_road_proba)
			){
				create road {
					lanes <- 2;
					shape <- polyline(reverse(r.shape.points));
					maxspeed <- r.maxspeed;
					linked_road <- r;
					r.linked_road <- self;
				}
			}
		}
		
		ask road {display_shape <- compute_display_shape();}
		
		ward(env).roads <- list<road>(road);
		env.road_network <- as_driving_graph(road,intersection);
		
		list<geometry> p_lines <- generate_pedestrian_network([],[],true,false,3.0,0.01,true,0.1,0.0,0.0);
		create corridor from: p_lines { do initialize distance:2#m; }
		
		env.pedestrian_network <- as_edge_graph(corridor);	
			
		create car number:number_of_vehicles with:[context::env] {
			
			location <- context.any_location(self);
			
			max_speed <- C_max_speed;
			vehicle_length <- C_length;
			vehicle_width <- C_width;
			max_acceleration <- C_max_acceleration;
			speed_coeff <- C_speed_coeff;
			
			right_side_driving <- V_right_side_driving;
			proba_lane_change_up <- V_proba_lane_change_up;
			proba_lane_change_down <- V_proba_lane_change_down;
			safety_distance_coeff <- V_safety_distance_coeff;
			proba_respect_priorities <- V_proba_respect_priorities;
			proba_respect_stops <- V_proba_respect_stops;
			proba_block_node <- V_proba_block_node;
			proba_use_linked_road <- V_proba_use_linked_road;
			
			 
		}
		
		ask people {
			switch species_of(self) {
				match simple_people {
					simple_people(self).obstacle_species << car;
				}
				match advanced_people {
					advanced_people(self).obstacle_species << car;
				} 
			}
		}
		
		
	}
	
	// Simple cross road
	list<geometry> simple_setup {
		float mid_x <- shape.width/2;
		float mid_y <- shape.height/2;
		
		return [
			line({mid_x,shape.height},{mid_x,0}),
			line({0,mid_y},{shape.width,mid_y})
		];
	}
	
	// Several cross roads
	list<geometry> multiple_setup {
		float x_length <- shape.width/x_lain_nb;
		float y_length <- shape.height/y_lain_nb;
		
		list<geometry> lines;
		
		loop x from:1 to:x_lain_nb-1 {
			
			lines <+ line({x_length*x,shape.height},{x_length*x,0});
		}
		
		loop y from:1 to:y_lain_nb-1 {
			lines <+ line({0,y_length*y},{shape.width,y_length*y});
		}
		
		return lines;
	}
	
	// Generated road network
	// TODO : find a procedural way to generate road network ;)
	list<geometry> complex_setup {
		
		create intersection number:number_of_intersections;
		graph<road,intersection> small_world <- generate_watts_strogatz(intersection, road, 0.04, 2, true);
		
		//small_world <- layout(small_world, "fruchtermanreingold", 10);
		//small_world <- layout(small_world, "circle", 10);
		
		return small_world.edges;
	}
	
}

experiment CrossRoadSetup parent:lab {
	
	output {
		display main {
			
			species road;
			species intersection;
			species car;
			species simple_people;
			species advanced_people;
			
		}
	}
}

experiment CrossRoadVehicleOnly parent:vehcile_lab {
	
	output {
		display main {
			
			species road aspect:base;
			species intersection;
			species car aspect:base;
			
		}
	}
}
