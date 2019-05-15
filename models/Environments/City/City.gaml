/***
* Name: City
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model City

import "../Environment.gaml"
import "../Ward/ward.gaml"

species city parent:environment {
	
	list<ward> wards;
	
	list<block> get_blocks { return wards accumulate each.get_blocks();}
	
	block current_block(agent the_agent) {
		return (wards first_with (the_agent overlaps each)).current_block(the_agent);
	}
	
	point any_location(agent the_agent) {
		return any(wards).any_location(the_agent);
	}
	
	point any_destination(agent the_agent) {
		return any(wards - wards first_with (the_agent overlaps each)).any_destination(the_agent);
	}
	
}
