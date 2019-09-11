/***
* Name: Environment
* Author: kevinchapuis
* Description: The highest abstraction level of the Trafic Lab. Define what is a general environment: the smallest one is a building, 
* then a ward (collection of building) and finally a city (collection of ward). The block are the basic constituent of an environment: 
* room for a building, building and road for a ward, ward for a city
* Tags: Tag1, Tag2, TagN
***/

model Environment

import "Road.gaml"

/*
 * The higher order abstraction for Trafic Lab
 * 
 * TODO : split into vehicle and vehicle free environment
 */
species environment virtual:true{
	
	/*
	 * Mobility graph for vehicles and pedestrian
	 */
	graph<road,intersection> road_network;
	graph<corridor> pedestrian_network;
	
	/*
	 * The blocks content of the environment (that can also be environment)
	 */
	list<block> get_blocks virtual:true {}
	
	/*
	 * The current block within the environment any agent is in
	 */
	block current_block(agent the_agent) virtual:true {}
	
	/*
	 * Any location in the environment
	 */
	point any_location(agent the_agent) virtual:true {}
	
	/*
	 * Any valide destination in the environment, e.g. if agent is a vehicle will return 
	 * any reachable point in the transportation system.
	 * 
	 * TODO : could actually return a block
	 */
	point any_destination(agent the_agent) virtual:true {}
	
}

/*
 * The basic abstract constituent of environments
 */
species block { 
	
	environment env;
	
	/*
	 * Is the block containing the given agent
	 */
	bool contains_agent(agent the_agent) virtual:true {}
	
	/*
	 * The list of neighboors block
	 */
	list<block> neighboors virtual:true {}
	
}

