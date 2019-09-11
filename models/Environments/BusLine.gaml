/***
* Name: BusLine
* Author: kevinchapuis
* Description: Define global feature to init and manage bus line using public_transport plugin
* Tags: Trafic, Public transport, Bus
***/

model BusLine

import "../Agents/Vehicle.gaml"

global {
	
	/*
	 * A Method to randomly generate public transport bus lines
	 * 
	 * TODO : add parameter to tweak bus stop creation on bus line path (e.g. every n meter) 
	 */
	graph<road,intersection> generate_public_transport(graph<road,intersection> road_net, 
		map<string,rgb> bus_lines_color, float average_bus_speed <- 40#km/#h, 
		bool debug_mode <- false, float proba_bus_stop_on_segment <- 0.4
	) {
		
		if debug_mode {write "Start generating public transport from scratch";}
		
		list<point> in_out <- intersection where each.inout collect each.location;
			
		// Create bus lines
		map<string,path> bus_lines;
		loop bl over:bus_lines_color.keys {
			point start <- any(in_out);
			in_out >- start;
			point end <- any(in_out);
			in_out >- end;
			add path_between(road_net,start,end) at:bl to:bus_lines;
		}
		
		if debug_mode {write "\nDefined "+length(bus_lines)+" : 
			\n"+bus_lines.pairs collect (each.key+" with total length of "+each.value.distance+"m\n");
		}
		
		// Create bus stops
		map<string, list<bus_stop>> bus_stops;
		loop bl over:bus_lines.keys {
			add random_bus_stop_on_path(bus_lines[bl], proba_bus_stop_on_segment) at:bl to:bus_stops;
		}
		
		// update graph with new intersections (bus stops)
		loop bs over:bus_stop {
			ask [bs.on_road,bs.on_road.linked_road] {
				int mylanes <- lanes;
				create road with:[shape::line(first(self.shape.points),bs.location),
					env::env,lanes::lanes,maxspeed::maxspeed
				];
				create road with:[shape::line(bs.location::last(self.shape.points)),
					env::env,lanes::lanes,maxspeed::maxspeed
				];  
				do die;
			}
		}		
		graph<road,intersection> result_graph <- as_driving_graph(road, intersection+bus_stop);
		
		if not(result_graph.vertices contains_all bus_stop) {error "Bus stops have not been put in the road network correctly";}
		
		if debug_mode {write "\nDefined bus stops : \n"
			+bus_stops.pairs collect (each.key+" => "+length(each.value)+"\n");
		}
		
		list<date> departure_times;
		date bd <- #epoch;
		loop h over:[6,7,8,9,10,11,12,13,14,15,16,17,18,19,20] {
			loop m over:[0,20,40] { departure_times <+ date([bd.year,bd.month,bd.days_in_month,h,m,0]); }
		}
		
		// Create bus schedule
		loop bl over:bus_stops.keys {
			
			list<bus_stop> foward_bus_stop <- bus_stops[bl];
			path foward_line <- bus_lines[bl];
			
			if debug_mode {write "Start loading bus line "+bl+">>"
				+" [len="+foward_line.distance+";stops="+length(foward_bus_stop)+"]";
			}
			
			// FOWARD BUS LINE = NAME + ">>"
			create bus_line with:[name::bl+">>",color::bus_lines_color[bl],
				the_stops::foward_bus_stop as_map (bl+">>"+(foward_bus_stop index_of each) :: each),
				the_path::foward_line,next_departure::1
			] {
				loop s over:the_stops {s.bus_lines <+ self;}
				do setup_schedule(myself.estimated_travel_time(result_graph, bus_lines[bl],
					foward_bus_stop, average_bus_speed, bl+">>", debug_mode
				), departure_times, debug_mode);
			}
			
			
			list<bus_stop> reverse_bus_stop <- reverse(copy(bus_stops[bl])); 
			path reverse_line <- path_between(result_graph, point(last(bus_lines[bl].vertices)), point(first(bus_lines[bl].vertices)));
			
			if debug_mode {write "Start loading bus line >>"+bl
				+" [len="+reverse_line.distance+";stops="+length(reverse_bus_stop)+"]";
			}
			
			create bus_line with:[name::">>"+bl,color::bus_lines_color[bl],
				the_stops::reverse_bus_stop as_map (bl+"<<"+reverse_bus_stop index_of each :: each),
				the_path::reverse_line,next_departure::1
			] {
				loop s over:the_stops {s.bus_lines <+ self;}
				do setup_schedule(myself.estimated_travel_time(result_graph, reverse_line,
					reverse_bus_stop, average_bus_speed, ">>"+bl, debug_mode
				), departure_times, debug_mode);
			}
			
		}
		return result_graph;
	}
	
	/*
	 * Randomly creates bus stop on a path
	 */
	list<bus_stop> random_bus_stop_on_path(path the_path, float proba_bus_stop_on_segment) {
		list<bus_stop> bus_line_stops;
		
		// Starting bus stop
		create bus_stop with:[on_road::road(first(the_path.edges)),
			location::intersection(the_path.source).location
		] returns:bs;
		bus_line_stops <+ bs[0];
		
		// Loop over other stops
		loop r from:1 to:length(the_path.edges)-2 {
			if flip(proba_bus_stop_on_segment) {
				road the_road <- road(the_path.edges[r]);
				
				bus_stop new_bs <- bus_stop first_with (each.on_road = the_road);
				if new_bs = nil {
					create bus_stop with:[on_road::the_road,location::any_location_in(the_road)] returns:bs;
					new_bs <- bs[0];
				} 
				bus_line_stops <+ new_bs;
			}
		}
		
		// Ending bus stop
		create bus_stop with:[on_road::road(last(the_path.edges)),
			location::intersection(the_path.target).location
		] returns:bs;
		bus_line_stops <+ bs[0];
		
		return bus_line_stops;
	}
	
	/*
	 * compute estimated travel time between bus stops
	 */
	map<bus_stop,float> estimated_travel_time(graph on_graph, path line_path, 
		list<bus_stop> b_stops, float average_bus_speed, 
		string bl, bool debug_mode
	) {
		
		float line_time <- line_path.distance / average_bus_speed * rnd(0.9,1.2); // Add some delay 1.2
		
		// Time between stops
		map<bus_stop,float> bs_time <- [b_stops[0]::0.0]; 
		loop ip from:1 to:length(b_stops)-1 {
			float l <- topology(on_graph) distance_between [b_stops[ip-1],b_stops[ip]];
			
			write "distance between "+b_stops[ip-1]+" and "+b_stops[ip]+" is "+l;
			
			add l / line_path.distance * line_time at:b_stops[ip] to:bs_time;
		}
		
		if debug_mode {write sample(bs_time.values);}
			
		return bs_time; 
	}
	
}

species bus_line skills:[escape_publictransport_scheduler_skill]{
	
	string name;
	
	path the_path;
	map<string, bus_stop> the_stops;
	list<bus> the_buses;
	
	rgb color;
	
	/*
	 * Built in variable with:
	 * matrix[0] = list of bus stop name
	 * matrix[0][1...n] = list of bus stop scheduled bus arrivals
	 */
	matrix schedule;
	
	reflex manage_bus {
		//  TODO : manage bus end and start line
		ask the_buses where (each.location = last(the_stops.values) and empty(each.passengers)) {
			do die;
		}
		
		list<int> stop_times <- check_departure(); // Check for a departure
		
		if not empty(stop_times) {
			create bus with:[line_name::name] {
				do define_route stops:myself.the_stops.values schedule:stop_times;
				do init_departure;
				add self to:myself.the_buses;
			}
		}
		
	}
	
	/*
	 * Setup a very simple schedule : depart every 'start_time' from first stop of the line, with pre-computed elapsed time between stops
	 */
	action setup_schedule(map<bus_stop, float> stops_time, list<date> start_time, bool debug_mode) {
		matrix mat <- {length(the_stops), length(start_time)+1} matrix_with "NA";
		
		if debug_mode {write "\nSetup schedule for bus line "+name+"\n";}
		
		// TODO : test if stops_time.keys is the same as the_stops.values; that is same ordering of bus stop
		map<bus_stop, string> reverse_stop <- the_stops.pairs as_map (each.value :: each.key);
		
		if not (reverse_stop.keys contains_all stops_time.keys) or length(stops_time) != length(reverse_stop) {
			error "Stops time and given bus stops for the line "+name+" are not complient\n"
				+sample(stops_time)+"\n"+sample(reverse_stop);
		} else {
			if debug_mode {write "Bus line "+name+" is composed of "+reverse_stop.values+" bus stops";}
		}
		
		int sid;
		loop sp over: stops_time.keys { mat[{sid,0}] <- reverse_stop[sp]; sid <- sid + 1;}
		
		int dnb <- 1;
		loop hd over:start_time {
			date stop_date <- date(hd);
			int snb <- 0;
			loop dp over: stops_time {
				stop_date <- stop_date + dp#s;
				mat[{snb,dnb}] <- string(stop_date.hour)+":"+string(stop_date.minute);
				snb <- snb + 1;
			}
			dnb <- dnb + 1;
		} 
		
		if debug_mode {write "["+sample(self)+"] try to setup the schedule with matrix \n"+transpose(mat);}
		
		do define_schedule schedule:transpose(mat);
		
		if debug_mode {write "["+sample(self)+"] registered bus stops are: "+sample(stops);}
		
		do check_next_departure; // Init departure ... 
	}
	
	aspect default {
		draw union(the_path.segments) buffer 4#m color:color;
		// loop s over:the_stops {draw square(1) at:s color:color border:#white;}
	}
	
}