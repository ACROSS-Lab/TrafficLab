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
	
	int nb_bus_lines parameter:true init:0 max:12 category:"Public transport";
	
	int number_of_vehicles parameter:true init:20 min:2 max:100 category:vehicle;
	bool autonomous_vehicles init:true category:vehicle;
	
	// Multiple args
	int x_lain_nb <- 8;
	int y_lain_nb <- 4;
	// Complex args
	float scale_free_proba;
	// Two way road probability
	float two_way_road_proba <- 1.0;
	
	geometry shape <- rectangle(world_size);
	
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
		
		// INIT PUBLIC TRANSPORT
		if setup != "simple" and nb_bus_lines > 0 {
			do generate_public_transport;
		}
		
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
				match simple_people { simple_people(self).obstacle_species << car; }
				match advanced_people { advanced_people(self).obstacle_species << car; } 
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
	
	// ---------------- //
	// public transport //
	// ---------------- //
	
	action generate_public_transport {
		
		if debug_mode {write "Start generating public transport from scratch";}
		
		list<point> in_out <- intersection where each.inout collect each.location;
			
		// Create bus lines
		map<string,path> bus_lines;
		int bus_line_nb <- 1;
		loop times:nb_bus_lines {
			point start <- any(in_out);
			in_out >- start;
			point end <- any(in_out);
			in_out >- end;
			add path_between(env.road_network,start,end) at:string(bus_line_nb) to:bus_lines;
			bus_line_nb <- bus_line_nb + 1;
		}
		
		if debug_mode {write "Defined "+length(bus_lines)+" : 
			\n"+bus_lines.pairs collect (each.key+" with total length of "+each.value.distance+"m\n");
		}
		
		// Create bus stops
		map<string, list<point>> bus_stops;
		loop bl over:bus_lines.keys {
			path the_path <- bus_lines[bl];
			list<point> bus_line_stops <- [the_path.source];
			loop r from:1 to:length(the_path.segments)-2 {
				if flip(0.4) { bus_line_stops <+ any_location_in(the_path.segments[r]); }
			}
			bus_line_stops <+ the_path.target;
			add bus_line_stops at:bl to:bus_stops;
		}
		
		if debug_mode {write "Defined bus stops : \n"
			+bus_stops.pairs collect (each.key+" => "+length(each.value)+"\n");
		}
		
		list<date> departure_times;
		date bd <- #epoch;
		loop h over:[6,7,8,9,10,11,12,13,14,15,16,17,18,19,20] {
			loop m over:[0,20,40] { departure_times <+ date([bd.year,bd.month,bd.days_in_month,h,m,0]); }
		}

		// update graph with new intersections (bus stops) 		
		env.road_network <- as_driving_graph(road, intersection+bus_stop);
		
		// Create bus schedule
		int bus_iter <- 0;
		loop bl over:bus_stops.keys {
			path line_path <- bus_lines[bl];
			float line_time <- line_path.distance / base_bus_speed * 1.2; // Add some delay 1.2
			
			if debug_mode {write "Start loading bus line "+bl
				+" [len="+line_path.distance+";stops="+length(bus_stops[bl])+";time="+line_time+"]";
			}
			
			// Time between stops
			map<point,float> bs_time; 
			list<point> b_stops <- bus_stops[bl];
			loop ip from:1 to:length(b_stops)-1 {
				float l <- topology(env.road_network) distance_between [b_stops[ip-1],b_stops[ip]];
				add l / line_path.distance * line_time at:b_stops[ip] to:bs_time;
			}
			
			// BUS LINE = NAME + ">>"
			create bus_line with:[name::bl+bus_dir,color::bus_palette[bus_iter],
				the_stops::b_stops as_map (bl+">>"+b_stops index_of each :: each),
				the_path::line_path
			] {
				do setup_schedule(bs_time,departure_times);
			}
			
			// Reverse time between stops
			map<point,float> r_bs_time <- [last(bs_time.keys)::0];
			list<float> reverse_time <- reverse(copy(bs_time.values));
			list<point> reverse_bus_stop <- reverse(copy(b_stops)); 
			int iter;
			loop ip over:reverse_bus_stop where each != last(b_stops) {
				add reverse_time[iter] at:ip to:r_bs_time;
				iter <- iter + 1;
			}
			
			// BUS LINE = ">>" + NAME
			path reverse_line <- path_between(env.road_network, point(last(line_path.vertices)), point(first(line_path.vertices)));
			create bus_line with:[name::bus_dir+bl,color::bus_palette[bus_iter],
				the_stops::reverse_bus_stop as_map (bl+"<<"+reverse_bus_stop index_of each :: each),
				the_path::reverse_line
			] {
				do setup_schedule(r_bs_time,departure_times);
			}
			
			bus_iter <- bus_iter + 1;
		}
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

experiment WardPublicTransport parent:vehicle_lab {

	parameter "bus line number" var:nb_bus_lines init:3 min:0 max:12 category:"Public transport";
	parameter "setup" var:setup init:"multiple" category:"Transport system";
	parameter "world size" var:world_size init:{2000,2000} category:"Global";
	
	output {
		display main {
			species bus_stop;
			species road;
			species bus;
		}
	}
	
}
