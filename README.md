# TrafficLab

A set of models that explore each traffic related feature of the Gama platform in abstract environment

 * 1. Pedestrian : people can go through a complex environment avoiding obstacle using a Social Force Model
 * 2. Driving : vehicle that follow a road network
 * 3. Public Transport : schedule public transport to follow a route and stops agenda
 
## Installation

You need to have a set of plugins to run the models:

 * Pedestrian skill (from Escape project - private forge, but you can ask for a packaged version)
 * Public Transport skill (from Escape project too)

## Next

 * Mutli-modality including multi-modal shortest path computation and rerouting
 * Multi-level simulation optimization (each environment -- e.g. building, ward -- has two dynamic model) with a simplified and fast version of each block of the model
