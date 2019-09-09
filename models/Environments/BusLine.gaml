/***
* Name: BusLine
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BusLine

import "../Agents/Vehicle.gaml"

species bus_line skills:[escape_publictransport_scheduler_skill]{
	
	string name;
	
	path the_path;
	map<string, point> the_stops;
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
	action setup_schedule(map<point, float> stops_time, list<date> start_time) {
		matrix mat <- {length(the_stops),length(start_time)+1} matrix_with 0.0;
		
		// TODO : test if stops_time.keys is the same as the_stops.values; that is same ordering of bus stop
		map<point, string> reverse_stop <- the_stops.pairs as_map (each.value :: each.key);
		
		if not (reverse_stop.keys contains_all stops_time.keys) {
			write "Stops time and given bus stops for the line "+name+" are not complient";
		} else {
			write "Bus line "+name+" is composed of "+reverse_stop.values+" bus stops";
		}
		
		int sid;
		loop sp over: stops_time.keys { mat[{0,sid}] <- reverse_stop[sp]; sid <- sid + 1;}
		
		int dnb <- 1;
		loop hd over:start_time {
			date stop_date <- copy(hd);
			int snb <- 0;
			loop dp over: stops_time {
				stop_date <- stop_date + dp;
				mat[{snb,dnb}] <- string(stop_date.hour)+":"+string(stop_date.minute);
				snb <- snb + 1;
			}
			dnb <- dnb + 1;
		} 
		
		write "["+sample(self)+"] try to setup the schedule with matrix: \n"+mat;
		
		do define_schedule schedule:mat;
		do check_next_departure; // Init departure ... 
	}
	
	aspect default {
		draw union(the_path.segments) color:color;
		loop s over:the_stops {draw square(1) at:s color:color border:#white;}
	}
	
}