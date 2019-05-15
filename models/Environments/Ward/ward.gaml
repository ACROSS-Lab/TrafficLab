/***
* Name: ward
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ward

import "../Environment.gaml"
import "../Building/Building.gaml"
import "../Road.gaml"

import "../../Agents/People.gaml"
import "../../Agents/Vehicle.gaml"

species ward parent:environment {
	
	list<building> buildings;
	list<road> roads;
	
	list<block> get_blocks {
		return (buildings accumulate each.get_blocks()) + roads;
	}
	
	block current_block(agent the_agent) {
		return get_blocks() first_with (each.contains_agent(the_agent));
	}
	
	point any_location(agent the_agent) {
		
		switch species_of(the_agent).parent {
			match people {
				return length(buildings) > 0 ? any_location_in(any(buildings)) : any_location_in(self);
			}
			match vehicle {
				return any_location_in(any(roads));
			}
			default {
				return any_location_in(self);
			}
		}
		
	}
	
	point any_destination(agent the_agent) {
		
		switch species_of(the_agent).parent {
			match people {
				list<building> regex <- buildings where (each.get_blocks() all_match (!each.contains_agent(the_agent)));
				return length(buildings) > 0 ? any_location_in(any(regex)) : any_location_in(self);
			}
			match vehicle {
				return any(road_network.vertices).location;
			}
			default {
				return any_location_in(self);
			}
		}
		
	}
}

