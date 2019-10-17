/***
* Name: SimpleBuildingSetup
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SimpleBuildingSetup

import "Agents/People.gaml"
import "Environments/Road.gaml"
import "Environments/Building.gaml"
import "Utils/GridEnvironment.gaml"
import "AbstractLab.gaml"

global {
	
	bool debug_mode <- true parameter:true category:"display";
	
	// Building parameters
	string building_type parameter:true among:["simple","complex"] init:"complex" category:building;
	
	float step <- 1#s/10;
	
	geometry shape <- square(int(world_size.x+world_size.y/2));
	
	float corridor_size <- 2#m;
	
	// DEBUG
	list<geometry> walls_with_door_one;
	
	init{
		
		if verbose {write "Create "+building_type+" building";}
		
		switch building_type {
			match "complex" {
				env <- create_building_from_gs(build_gridshape(world.shape,{10,10}));
			} 
			match "simple" {
				env <- create_building_from_sh(world.shape);
			}
		}
		
		ask people {
			switch species_of(self) {
				match simple_people {
					simple_people(self).obstacle_species << wall;
				}
				match advanced_people {
					advanced_people(self).obstacle_species << wall;
				} 
			}
		}
		
	}
	

}


experiment BuildingSetup parent:lab {

	parameter "Door width" var:door_width min:0.5#m max:10#m category:building;

	output {
		display "Building" {
			
			species room;
			species door;
			species wall;
			agents value:agents of_generic_species people;
			
			species corridor aspect: hub;
			
			graphics "walls with door" {
				loop w over:walls_with_door_one {draw w color:#gold;}
			}
			
		}
	}
}
	


