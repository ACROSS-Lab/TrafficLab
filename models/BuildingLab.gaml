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
	float proba_expand_room parameter:true init:0.9 max:0.99 category:building;
	
	float step <- 1#s/10;
	
	geometry shape <- square(int(world_size.x+world_size.y/2));
	
	// DEBUG
	list<geometry> walls_with_door_one;
	
	init{
		
		switch building_type {
			match "complex" {
				do create_building(build_gridshape(world.shape,{10,10}));
			} 
			match "simple" {
				do create_simple_building(world.shape);
			}
		}
		
		env <- building[0];
		
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
			
			species corridor;
			
			graphics "walls with door" {
				loop w over:walls_with_door_one {draw w color:#gold;}
			}
			
		}
	}
}
	


