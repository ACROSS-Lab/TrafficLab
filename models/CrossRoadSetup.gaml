/***
* Name: CrossRoadSetup
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CrossRoadSetup

import "Agents/Road.gaml"
import "Agents/Vehicle.gaml"

global {
	
	bool debug_mode <- true;
	
	int number_of_people parameter:true init:20 min:0 max:100 category:pedestrian;
	string people_type parameter:true among:["simple","advanced"] init:"advanced" category:pedestrian;
	string pedestrian_aspect <- "default" parameter:true among:["default","path","destrination"] category:pedestrian;
	
	string setup <- "simple" parameter:true among:["simple", "multiple", "complex"] category:"transport system";
	int number_of_intersections parameter:true init:20 min:5 category:"transport system";
	
	int number_of_vehicles parameter:true init:20 min:2 max:100 category:vehicle;
	bool autonomous_vehicles parameter:true init:true category:vehicle;
	
	// Multiple args
	int x_lain_nb <- 8;
	int y_lain_nb <- 4;
	// Complex args
	float scale_free_proba;
	// Two way road probability
	float two_way_road_proba <- 1.0;
	
	graph road_network;
	graph pedestrian_network;
	
	init {
		
		list<geometry> lines;
		
		switch setup {
			match "simple" {lines <- simple_setup();}
			match "multiple" {lines <- multiple_setup();}
			match "complex" {lines <- complex_setup();}
		}
		
		create road from:split_lines(lines) with:[lanes::1];
		
		loop p over:as_edge_graph(road).vertices collect each.location{
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
					lanes <- 1;
					shape <- polyline(reverse(r.shape.points));
					maxspeed <- r.maxspeed;
					linked_road <- r;
					r.linked_road <- self;
				}
			}
		}
		
		road_network <- as_driving_graph(road, intersection);
		
		list<geometry> p_lines <- generate_pedestrian_network([],[],true,false,3.0,0.01,true,0.1,0.0,0.0);
		create pedestrian_path from: p_lines { do initialize distance:2#m; }
		pedestrian_network <- as_edge_graph(pedestrian_path);	
			
		
		create car number:number_of_vehicles {
			road r <- any(road);
			location <- any_location_in(r);
			// current_road <- r; // TODO : why there is a bug with this ?
			road_network <- myself.road_network;
		}
		
		if(people_type="simple"){
			create simple_people number:number_of_people {
				obstacle_species <- [car];
			}
		} else if (people_type="advanced"){
			create advanced_people number:number_of_people {
				obstacle_species <- [car, people];
				pedestrian_network <- myself.pedestrian_network;
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
		
		small_world <- layout(small_world, "fruchtermanreingold", 10);
		//small_world <- layout(small_world, "circle", 10);
		
		return small_world.edges;
	}
	
}

experiment CrossRoadSetup type: gui {
	
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
