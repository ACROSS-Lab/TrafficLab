/***
* Name: VirtualLane
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model VirtualLane

species virtual_lane_vehicle skills:[moving] { //schedules:virtual_lane_vehicle sort (each distance_to current_goal) {
	
	float speed <- 40#km/#h;
	
	// Vehicle shape
	float width <- 1#m;
	float height <- 1.75#m;
	
	// Vehicle virtual positionning
	virtual_road current_road;
	float rigth_align;
	bool blocked <- false;
	
	float side_move <- 1#m;
	
	float safety_distance <- 1#m;
	
	// Road network
	graph transport_system;
	
	// Path
	point target;
	point current_goal;
	path my_path;
	
	int current_index;
	
	init {
		if(current_road=nil){
			current_road <- virtual_road first_with (self overlaps each.virtual_shape);
		}
	}
	
	/*
	 * Path management
	 */
	reflex find_path when:target=nil {
		target <- any(transport_system.vertices);
		current_index <- 0;
		my_path <- path_between(transport_system, location, target);
		if(current_road=nil){
			current_road <- virtual_road first_with (self overlaps each.virtual_shape);
			if(current_road=nil){
				current_road <- virtual_road with_min_of (self distance_to each.virtual_shape);
			}
		}
		point fg <- my_path.vertices[current_index];
		heading <- location towards fg;
	}
	
	/*
	 * Follow path management
	 */
	reflex follow_path when:my_path!=nil{
		
		point prev_loc <- copy(location);
		point current_step_goal <- my_path.vertices[current_index];
		
		float desired_distance_current_move <- speed * step; 
		
		// LOOP OVER THE DIFFERENT SEGMENT ROAD OF THE PATH
		loop while: not(blocked or desired_distance_current_move <= 0) {
			
			// Should move the agent until current_step_goal is reached OR being blocked
			desired_distance_current_move <- goto_virtual_lane(current_road, current_step_goal, desired_distance_current_move);
			
			if(location = current_step_goal){
				if(current_step_goal = last(my_path.vertices)){
					// Arrived at destination
					target <- nil;
					my_path <- nil;
				} else {
					current_index <- current_index + 1;
					current_step_goal <- my_path.vertices[current_index];
					heading <- location towards current_step_goal;
				}
			}
		}
		
	}
	
	////////////////////////////////////////////////////////////////////////////////////////
	// IN VIRTUAL LANE MOVEMENT
	////////////////////////////////////////////////////////////////////////////////////////
	
	/*
	 * Simple goto with virtual lane : vehicle use virtual lane only when blocked by obstacle
	 */
	float goto_virtual_lane(virtual_road v_lane, point v_lane_goal, float desired_distance){
		float actual_distance;
		
		// 1 : Check for obstacles 
		geometry my_v_lane <- v_lane.vehicle_virtual_lane(self,0);
		virtual_lane_vehicle obstacle <- v_lane.is_any_obstacles(self, my_v_lane);
		
		bool reached_goal <- false;
		
		// LOOP OVER VIRTUAL LANES WITHIN A ROAD SECTION
		loop while: not(blocked or reached_goal) {
			
			// 1.a IF NO OBSTACLE : reach v_lane_goal or desired_distance // EXIT
			if(obstacle=self){
				
				point actual_goal;
				float distance_to_goal <- self.location distance_to v_lane_goal;
				if(distance_to_goal <= desired_distance){
					actual_distance <- distance_to_goal;
				} else {
					actual_distance <- desired_distance;
					actual_goal <- (self.location + v_lane_goal) * desired_distance / distance_to_goal;
				}
				
				/* 
				write sample(self);
				write sample(actual_goal);
				write sample(desired_distance);
				write sample(actual_distance);
				* 
				*/
				
				do goto target:actual_goal on:transport_system;
				
				reached_goal <- true;
			
			} else {
				
				// 1.b IF ANY OBSTACLE : 
				//write sample(self)+" faces "+sample(obstacle);
				//write sample(self.location);
				if(obstacle=nil){
					error sample(self)+" faces "+sample(obstacle);
					ask world {do pause;}
				}
				
				// GO AHEAD UNTIL OBSTACLE
				float distance_to_obstacle <- location distance_to (obstacle.location - (obstacle.height / 2 + self.safety_distance));
				point stop_point;
				if(distance_to_obstacle > desired_distance) {
					stop_point <- (location + obstacle.location) * (desired_distance / distance_to_obstacle);
					distance_to_obstacle <- desired_distance - actual_distance;
				} else {
					stop_point <- (location + obstacle.location) * (distance_to_obstacle / location distance_to obstacle.location);
				}
				 
				do goto target:stop_point on:transport_system;
				
				// Update actual distance traveled
				actual_distance <- actual_distance + distance_to_obstacle;
				if(actual_distance = desired_distance) {
					return desired_distance - actual_distance;
				}
				
				//write sample(obstacle.location);
				//write sample(self.location);
				
				// Check for available up virtual lane
				float max_up <- v_lane.road_width - self.rigth_align - self.width/2;
				list<float> v_up_lanes;
				float s_move;
				loop while:s_move < max_up {
					s_move <- s_move + side_move;
					v_up_lanes <+ s_move;
				}
				map<float,list<virtual_lane_vehicle>> up_lanes <- v_up_lanes as_map (
					each::v_lane.all_obstacles(self,v_lane.vehicle_virtual_lane(self,each),-1)
				);
				pair<float,list<virtual_lane_vehicle>> available_up_vl <- available_sideway(up_lanes,current_road);
				
				if(int(self)=7) {write sample(available_up_vl);}
				
				// Check for available down virtual lane				
				float max_down <- self.rigth_align - self.width/2;
				list<float> v_down_lanes;
				s_move <- 0;
				loop while:abs(s_move) < max_down {
					s_move <- s_move - side_move;
					v_down_lanes <+ s_move;
				}
				map<float,list<virtual_lane_vehicle>> down_lanes <- v_down_lanes as_map (
					each::v_lane.all_obstacles(self,v_lane.vehicle_virtual_lane(self,each),-1)
				);
				pair<float,list<virtual_lane_vehicle>> available_down_vl <- available_sideway(down_lanes,current_road);
					
				if(int(self)=7) {write sample(available_down_vl);}
					
				// Decide on up or down virtual lane to move to			
				if(available_up_vl.key=0.0 and available_down_vl.key=0.0){
					blocked <- true;
				} else {
					
					// If there is a free virtual lane, takes it
					pair<float,list<virtual_lane_vehicle>> side_lane <- [available_up_vl,available_down_vl] first_with
						(first(each.value)=self and length(each.value)=1);
					
					// Else test for the longest free ride available virtual lane
					if(side_lane=nil or empty(side_lane)){
						if(available_up_vl.key=0.0){
							side_lane <- available_down_vl;
						} else if(available_down_vl.key=0.0){
							side_lane <- available_up_vl;
						} else {
							side_lane <- [available_up_vl,available_down_vl] with_max_of (
								distance_between(topology(transport_system),[each.value[1],self])
							);
						} 
						obstacle <- side_lane.value[1];
					} else {
						obstacle <- first(side_lane.value);
					}
					
					actual_distance <- actual_distance + goto_sideway(
							side_lane.key,distance_ahead_to_overcome(), // up and ahead distance
							desired_distance-actual_distance, // actual distance = hypothenuse
							v_lane_goal
						);
					
					// Update rigth align and the obstacle to go ahead
					// TODO : compute actual side move, because desired_distance could be inferior to actual distance to go sideway 
					self.rigth_align <- self.rigth_align + side_lane.key;
					
					if(actual_distance = desired_distance) {
						return desired_distance - actual_distance;
					}
				}
				
			}
		}
		
		return desired_distance - actual_distance;
	}
	
	/*
	 * Complex goto with virtual lane : vehcile try to dive into the traffic looking at several paths between other vehicles
	 */
	float goto_virtual_lane_with_virtual_network(virtual_road v_lane, point v_lane_goal, float desired_distance){
		float actual_distance;
		
		// FIRST STEP : compute the virtual network from current location to v_lane_goal or closest possible position
		
		// IF ANY PATH : go for i) any ii) statisfactory iii) the shortest one
		
		// IF NONE : go i) ahead until blocked ii) closest end point to v_lane_goal
		
		return desired_distance - actual_distance;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////
	// SIDEWAY MOVEMENT
	////////////////////////////////////////////////////////////////////////////////////////
	
	/*
	 * Test successive virtual lane (up or down) to find available one, assess if blocked, and so on
	 * 
	 * WARNING : remove the obstacle vehicle behind self !!!!! beware of side effect
	 *  
	 */
	pair<float,list<virtual_lane_vehicle>> available_sideway(map<float,list<virtual_lane_vehicle>> v_lanes, virtual_road v_road) {
		
		int self_idx <- v_road.registered_vehicles index_of self;
		pair<float,list<virtual_lane_vehicle>> best_virtual_lane;
		float best_distance_to_obstacle;
		
		loop virtualane over:copy(v_lanes).pairs {
			// If next available virtual lane is empty then move to it 
			if(first(virtualane.value)=self and length(virtualane.value)=1){
				if(int(self)=7) {write sample(virtualane.value);}
				return virtualane;
			} else {
				// If next obstacle 
				virtual_lane_vehicle obs <- first(virtualane.value);
				int obs_idx <- v_road.registered_vehicles index_of obs;
				if(obs_idx<self_idx){
					if (obs distance_to self < distance_behing_to_overcome()) {
						return 0::[];						
					} else {
						remove obs from:virtualane;
						if(first(virtualane.value)=self and length(virtualane.value)=1){
							return virtualane;
						}
						obs <- virtualane[1];
						obs_idx <- v_road.registered_vehicles index_of obs;
					}
				}
				float current_distance_to_obstacle <- self distance_to obs;
				if(obs_idx>self_idx and current_distance_to_obstacle < distance_ahead_to_overcome()){
					return 0::[];
				} else { 
					if(best_virtual_lane=nil or best_distance_to_obstacle < current_distance_to_obstacle){
						best_virtual_lane <- virtualane;
						best_distance_to_obstacle <- current_distance_to_obstacle;
					}
				}
			}
		}
		
		return best_virtual_lane;

	}
	
	/*
	 * Move the vehicle sideway and return actual distance moved
	 */
	float goto_sideway(float distance_sideway, float distance_ahead, float available_distance, point goal){
		float real_distance <- sqrt(distance_sideway^2+distance_ahead^2);
		if(available_distance < real_distance){
			distance_sideway <- distance_sideway * real_distance / (real_distance - available_distance);
			distance_ahead <- distance_ahead * real_distance / (real_distance - available_distance);
		}
		point stop_point <- (location + goal) * (distance_ahead / (location distance_to goal));
		do goto target:stop_point on:transport_system;
		return real_distance;
	}
	
	float distance_ahead_to_overcome {
		return self.height; // TODO : depend on the speed
	}
	
	float distance_behing_to_overcome {
		return sqrt(self.width^2+self.height^2)*2;
	}
	
	////////////////////////////////////////////////////////////////////////////////////////
	// VISUALIZATION
	////////////////////////////////////////////////////////////////////////////////////////
	
	point calcul_loc {
		if (current_road = nil) {
			return location;
		} else {
			float val <- current_road.road_width-rigth_align;
			return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
		}
	}
	
	geometry actual_shape {
		return (rectangle(width,height) at_location calcul_loc()) rotated_by heading;
	}
	
	aspect default {
		draw actual_shape();
		//draw circle(0.4) at:calcul_loc() color:#black;
	}
	
}

/************************
 * 
 * 
 * VIRTUAL ROAD
 * 
 * 
 ************************/
species virtual_road {
	
	list<virtual_lane_vehicle> registered_vehicles <- [];
	
	geometry virtual_shape;
	float road_width;
	
	rgb color;
	
	init {
		color <- rnd_color(255);
		virtual_shape <- get_expansion(shape,road_width,90);
	}
		
	/*
	 * orders registered vehicle from the last to first on (virtual) road line 
	 */
	reflex update_registered_vehicle_order when:length(registered_vehicles) > 1 {
		registered_vehicles <- registered_vehicles sort (each distance_to last(shape.points));
	}
	
	/*
	 * Return the virtual lane the vehicle is in
	 */
	geometry vehicle_virtual_lane(virtual_lane_vehicle virtual_vehicle, float up_down_lane_shift){
		
		if(not(registered_vehicles contains virtual_vehicle)) {
			error "vehicle not registered";
			return nil;
		}
		
		int down_lane_available <- virtual_vehicle.rigth_align - virtual_vehicle.width / 2;
		int up_lane_available <- road_width - virtual_vehicle.rigth_align - virtual_vehicle.width / 2;
		
		if(up_down_lane_shift < 0 and down_lane_available < abs(up_down_lane_shift)){
			// Lowest virtual lane possible on this road for this vehicle
			return get_expansion(self,virtual_vehicle.width,90);
		} else if(up_down_lane_shift > 0 and up_lane_available < up_down_lane_shift){
			// Uppest virtual lane possible on this road for this vehicle
			return virtual_shape - get_expansion(self,road_width-virtual_vehicle.width,90);
		} else {
			// Compute x down/up virtual lane
			int factor <- up_down_lane_shift < 0 ? -2 : 2;
			
			geometry exterior <- get_expansion(self,virtual_vehicle.rigth_align+up_down_lane_shift+virtual_vehicle.width/factor,90);
			geometry interior <- get_expansion(self,virtual_vehicle.rigth_align+up_down_lane_shift-virtual_vehicle.width/factor,90); 
			
			geometry top_bound <- factor < 0 ? interior : exterior;
			geometry bottom_bound <- factor < 0 ? exterior : interior;
		
			return top_bound - bottom_bound;
		}
	}
	
	/*
	 * Return the virual lane up
	 */
	geometry vehicle_virtual_lane_up(virtual_lane_vehicle virtual_vehicle){
		
		if(not(registered_vehicles contains virtual_vehicle)) {
			error "vehicle not registered";
			return nil;
		}
		
		return get_expansion(self,virtual_vehicle.rigth_align+virtual_vehicle.width*2,90)
			- get_expansion(self,virtual_vehicle.rigth_align+virtual_vehicle.width,90);
	}
	
	/*
	 * TODO : Should return any obstacle ! even can be a pedestrian for ex.
	 * 
	 * return the next obstacle that obstructs the virtual lane the vehicle is in OR
	 * the virtual_vehicle itself if there is no obstacle in the lane
	 * 
	 */
	virtual_lane_vehicle is_any_obstacles(virtual_lane_vehicle virtual_vehicle, geometry v_lane, int self_pointer <- 1) {
		list<virtual_lane_vehicle> res <- all_obstacles(virtual_vehicle,v_lane,self_pointer);
		
		// If asking for previous vehicle but there is no one AND there is infront obstacle, then return 
		// the index 1 vehicle (i.e. skip virtual_vehicle itself)
		if(res[0]=virtual_vehicle and length(res) > 1) {
			return res[1];
		}
		 
		return res[0];
	}
	
	/*
	 * returns all the (virtual_lane_vehicle) obstacle on the virtual lane
	 * 
	 * WARNING: the returned list includes virtual_vehicle itself
	 * 
	 */
	list<virtual_lane_vehicle> all_obstacles(virtual_lane_vehicle virtual_vehicle, geometry v_lane, int self_pointer <- 1) {
		if(length(registered_vehicles)=1 and registered_vehicles[0]=virtual_vehicle){ return [virtual_vehicle]; }
		
		//write "Looking at obstacles in virtual road "+sample(registered_vehicles);
		
		// If other people ahead, then proceed 
		int self_idx <- registered_vehicles index_of virtual_vehicle;
		
		if(self_idx+self_pointer < 0) {self_pointer <- -self_idx;}
		if(self_idx+self_pointer > length(registered_vehicles)-1) {self_pointer <- length(registered_vehicles)-1-self_idx;}
		
		list<virtual_lane_vehicle> res <- [];
		loop v from:self_idx+self_pointer  to:length(registered_vehicles)-1 {
			if(registered_vehicles[v] overlaps v_lane){
				add registered_vehicles[v] to:res;
			}
		}
		
		return empty(res)?[virtual_vehicle]:res;
	}
	
	/*
	 * Expand a geometry (a road line) with a given expansion and angle
	 */
	geometry get_expansion(geometry line, float expansion, int rotation_angle) {
		list<geometry> segs <- to_segments(line);
		list<geometry> segs_expansion;
		
		loop s over:segs {
			float simple_angle <- first(s.points) towards last(s.points) + rotation_angle;
			segs_expansion <+ polygon(
				first(s.points),
				last(s.points),
				point([last(s.points).x - expansion * cos(simple_angle), last(s.points).y - expansion * sin(simple_angle)]),
				point([first(s.points).x - expansion * cos(simple_angle), first(s.points).y - expansion * sin(simple_angle)])
			);
		}
		
		return union(segs_expansion);
	}

	
	aspect default {
		
		float simple_angle <- first(shape.points) towards last(shape.points) + 90;
		float val <- road_width / 2;
		geometry arrow2 <- (shape scaled_by (3#m/shape.perimeter));
		arrow2 <- arrow2 at_location (location + {cos(simple_angle) * val, sin(simple_angle) * val});
		 
		draw virtual_shape color:color border:#black;
		draw arrow2 color:#red end_arrow: 0.5;
	}
	
}

