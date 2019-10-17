/***
* Name: AbstractLaboratory
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model AbstractLaboratory

import "Environments/Environment.gaml"
import "Agents/People.gaml"

global {
	
	environment env;
	point world_size <- {100,100};
	
	// ------- //
	// LOG OUT //
	// ------- //
	
	bool verbose <- true; // (1) Info on higher order processes
	bool debug <- false; // (2) Debug within processes
	bool trace <- false; // (3) Inloop and very verbose debug
	
	// ------- //
	// VEHICLE //
	// ------- //
	
	float C_max_speed <- 120 #km / #h;
	float C_max_acceleration <- 5 / 3.6;
	float C_speed_coeff <- 1.2 - (rnd(400) / 1000);
	float C_length <- 5.0 #m;
	float C_width <- 2#m;
	
	bool V_right_side_driving <- true;
	float V_proba_lane_change_up <- 0.1 + (rnd(500) / 500);
	float V_proba_lane_change_down <- 0.5 + (rnd(500) / 500);
	float V_safety_distance_coeff <- 5 / 9 * 3.6 * (1.5 - rnd(1000) / 1000);
	float V_proba_respect_priorities <- 1.0 - rnd(200 / 1000);
	list V_proba_respect_stops <- [1.0];
	float V_proba_block_node <- 0.0;
	float V_proba_use_linked_road <- 0.0;
	
	// ---------------- //
	// PUBLIC TRANSPORT //
	// ---------------- //
	
	string bus_dir <- ">>";
	float base_bus_speed init:20 #km/#h;
	list<rgb> bus_palette init:brewer_colors("Set3",12);
	
	// ------ //
	// PEOPLE //
	// ------ //
	
	bool is_people;
	string people_type;
	
	int nb_pedestrian <- 0;
	
	float P_obstacle_distance_repulsion_coeff;
	float P_obstacle_repulsion_intensity;
	float P_overlapping_coefficient;
	float P_perception_sensibility;
	float P_shoulder_length;
	float P_tolerance_target;
	float P_proba_detour;
	bool P_avoid_other;
	
	list obs_species <- [people,vehicle];
	
	string pedestrian_aspect <- "default" parameter:true among:["default","path","destination"] category:"display";
	
	// Pedestrian network //
	
	bool reduced_angular_distance init:true;
	float corridor_size init:0.0;
	
	// -------- //
	// BUILDING //
	// -------- //
	
	float door_width <- 1.2#m;
	float wall_thickness <- 15#cm;

	/*________________
	 |				  |
	 | INITIALIZATION |
	 |________________|
	 				  */
	
	init {
		
		// ----------------------------------- //
		if verbose {write "Start creating people";}
		// ----------------------------------- //
		
		if(people_type = "simple"){
			create simple_people number:nb_pedestrian with:[
				location::env.any_location(self),
				current_environment::env,
				the_aspect::pedestrian_aspect
			]{
				obstacle_species <- obs_species;
				obstacle_distance_repulsion_coeff <- P_obstacle_distance_repulsion_coeff;
				overlapping_coefficient <- P_overlapping_coefficient;
				perception_sensibility <- P_perception_sensibility ;
				shoulder_length <- P_shoulder_length;
				avoid_other <- P_avoid_other;
				proba_detour <- P_proba_detour;
			}
		} else {
			create advanced_people number:nb_pedestrian with:[
				location::env.any_location(self),
				current_environment::env,
				the_aspect::pedestrian_aspect
			]{
				obstacle_species <- obs_species;
				obstacle_distance_repulsion_coeff <- P_obstacle_distance_repulsion_coeff;
				overlapping_coefficient <- P_overlapping_coefficient;
				perception_sensibility <- P_perception_sensibility ;
				shoulder_length <- P_shoulder_length;
				avoid_other <- P_avoid_other;
				proba_detour <- P_proba_detour;
				tolerance_target <- P_tolerance_target;
			}
		}
		
	}
	
	
}

experiment lab type:gui virtual:true {
	
	parameter "People" var:is_people init:true enables:[nb_pedestrian,people_type,corridor_size,
		P_obstacle_distance_repulsion_coeff,P_obstacle_repulsion_intensity,P_overlapping_coefficient,
		P_perception_sensibility,P_shoulder_length,P_tolerance_target,P_tolerance_target,
		P_proba_detour,P_avoid_other
	];
	parameter "Number of people" var:nb_pedestrian init:10 min:0 category:people;
	parameter "Type of people" var:people_type among:["simple","advanced"] init:"advanced" category:people;
	
	parameter "Size of corridors" var:corridor_size init:2.0 min:0.0 max:3#m category:pedestrian;
	parameter "Repulsion coefficient" var:P_obstacle_distance_repulsion_coeff init:1.0 category:pedestrian;
	parameter "Repulsion intensity" var:P_obstacle_repulsion_intensity init:2.0 category:pedestrian;
	parameter "Overlapping coefficient" var:P_overlapping_coefficient init:2.0 category:pedestrian;
	parameter "Perception sensitivity" var:P_perception_sensibility init:1.0 category:pedestrian;
	parameter "Shoulder length" var:P_shoulder_length init:0.5 category:pedestrian;
	parameter "Target tolerance" var:P_tolerance_target init:0.1 category:pedestrian;
	parameter "Probability to go backward" var:P_proba_detour init:0.5 category:pedestrian;
	parameter "Avoid other" var:P_avoid_other init:true category:pedestrian;
	
}

experiment vehicle_lab type:gui virtual:true {}

