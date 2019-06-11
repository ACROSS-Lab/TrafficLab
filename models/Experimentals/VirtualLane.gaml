/***
* Name: VirtualLane
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model VirtualLane

species virtual_lane {
	
	list<virtual_lane_vehicle> registered_vehicles;
	
	float road_width;
	
	rgb color <- rnd_color(255);
	
	aspect default {
		float angle_x <- atan2(shape.points[0].y - shape.points[0].y, shape.points[0].x + 1 - shape.points[0].x) 
			- atan2(shape.points[1].y - shape.points[0].y, shape.points[1].x - shape.points[0].x);
					
		float new_angle <- 0 - angle_x + 90;
					
		point p1 <- point([first(shape.points).x + road_width * cos(new_angle), first(shape.points).y + road_width * sin(new_angle)]);
		point p2 <- point([first(shape.points).x - road_width * cos(new_angle), first(shape.points).y - road_width * sin(new_angle)]);
		point p3 <- point([last(shape.points).x + road_width * cos(new_angle), last(shape.points).y + road_width * sin(new_angle)]);
		point p4 <- point([last(shape.points).x - road_width * cos(new_angle), last(shape.points).y - road_width * sin(new_angle)]);
		 
		geometry arrow1 <- line(shape.points collect (each*(1.0/3)));  
		geometry arrow2 <- line(first(shape.points) + last(shape.points)*(2.0/3) - last(shape.points)*0.1, 
			first(shape.points) + last(shape.points)*(2.0/3) + last(shape.points)*0.1);

		 
		draw polygon(first(shape.points),last(shape.points),p4,p2) color:color border:#black;
		draw arrow2 color:#black;
	}
	
}

species virtual_lane_vehicle skills:[moving] {
	
	// Vehicle shape
	float width <- 1#m;
	float height <- 1.75#m;
	
	// Vehicle virtual positionning
	virtual_lane current_lane;
	float rigth_align;
	
	// Road network
	graph transport_system;
	
	// Path
	point target;
	point sub_target;
	path my_path;
	
	reflex find_path when:target=nil {
		target <- any(transport_system.vertices);
		sub_target <- transport_system.vertices closest_to location;
		my_path <- path_between(transport_system, sub_target, target);
		
	}
	
	reflex follow_path when:sub_target!=nil{
		
		point prev_loc <- location;
		
		do goto target:sub_target;
		
		if(location=sub_target){
			if(empty(my_path)) {
				target <- nil;
			} else {
				int i <- my_path.edges index_of sub_target;
				if(i = length(my_path.edges) - 1){
					target <- nil;
				} else {
					sub_target <- my_path.edges[i+1].location;
				}
			}
		}
		
		if(prev_loc=location and sub_target!=target){
			write sample(location);
			write sample(sub_target);
			write sample(target);
			ask world {do pause;}
		}
	}
	
	point calcul_loc {
		if (current_lane = nil) {
			return location;
		} else {
			float val <- current_lane.road_width-rigth_align;
			return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
		}
	}
	
	aspect default {
		draw rectangle(width,height) at:calcul_loc() color:#lightgreen rotate:heading;
		draw circle(0.4) at:calcul_loc() color:#black;
	}
	
}

