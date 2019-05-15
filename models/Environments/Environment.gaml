/***
* Name: Environment
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Environment

import "Road.gaml"

species environment virtual:true{
	
	graph<road,intersection> road_network;
	graph<corridor> pedestrian_network;
	
	list<block> get_blocks virtual:true {}
	
	block current_block(agent the_agent) virtual:true {}
	
	point any_location(agent the_agent) virtual:true {}
	
	point any_destination(agent the_agent) virtual:true {}
	
}

species block { 
	
	bool contains_agent(agent the_agent) virtual:true {}
	
}

