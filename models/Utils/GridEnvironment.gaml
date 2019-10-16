/***
* Name: GridEnvironment
* Author: kevinchapuis
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model GridEnvironment

import "../AbstractLab.gaml"

global {
	
	string VONNEUMAN <- "vonneuman" const:true;
	string MOORE <- "moore" const:true; 
	
	/*
	 * Build a grid shape from a geometry and given squarification of the geometry
	 */
	gridshape build_gridshape(geometry gshape, point squarization){
		matrix m;
		
		if debug_mode {write "Build a gridshape from "+sample(gshape)+" with to_rectange using "+squarization;}
		
		list<geometry> squaredgeom <- gshape to_rectangles squarization;
		
		if debug_mode {write "Given geometry splits into "+length(squaredgeom)+" cells";}
		
		
		list<float> x_full <- squaredgeom collect (each.location.x);
		list<float> x_coord <- remove_duplicates(x_full);
		//list<float> x_coord_verified <- no_duplicates(squaredgeom collect (each.location.x), 0.01);
		int max_x <- max(x_coord count (x_full contains each));
		
		list<float> y_full <- squaredgeom collect (each.location.y);
		list<float> y_coord <- remove_duplicates(y_full);
		//list<float> y_coord_verified <- no_duplicates(squaredgeom collect (each.location.y), 0.01);
		int max_y <- max(y_coord count (y_full contains each));
		
		create gridshape returns:gs {
			grid <- {max_x,max_y} matrix_with nil;
			max_grid_x <- max_x;
			max_grid_y <- max_y;
			
			loop sq over:squaredgeom {
				create cell with:[shape::sq] {
					coordinate <- point(x_coord index_of location.x, y_coord index_of location.y);
					put self in:myself.grid at:coordinate;
				}
			}
			
		} 
		
		return gs[0];
	}
	
}

/*
 * A grid species based on any geometry </br>
 * As it is the case in Gama, underlying matrix is coordinated from upper (x=0) left (y=0) corner </p>
 */
species gridshape {
	
	// MAIN CONTENT
	matrix<cell> grid;
	int max_grid_x;
	int max_grid_y;
	
	string neighbor_type init:"vonneuman" among:["moore","vonneuman"];
	
	list<cell> neighbors(cell current_cell, string neighbor_type <- VONNEUMAN) {

		bool west <- current_cell.coordinate.y = 0;
		bool north <- current_cell.coordinate.x = 0;
		bool east <- current_cell.coordinate.y = max_grid_y;
		bool south <- current_cell.coordinate.x = max_grid_x;
		list<point> n_coords; // ==> From west, north, east to south !
		// VONNEUMAN 
		if not west {
			n_coords <+ current_cell.coordinate+{0,-1};
			if neighbor_type = MOORE {
				n_coords <+ current_cell.coordinate+{1,-1};
				n_coords <+ current_cell.coordinate+{-1,-1};
			}
		}
		if not north {
			n_coords <+ current_cell.coordinate+{-1,0};
			if neighbor_type = MOORE {
				n_coords <+ current_cell.coordinate+{-1,-1};
				n_coords <+ current_cell.coordinate+{-1,1};
			}
		}
		if not east {
			n_coords <+ current_cell.coordinate+{0,1};
			if neighbor_type = MOORE {
				n_coords <+ current_cell.coordinate+{1,1};
				n_coords <+ current_cell.coordinate+{-1,1};
			}
		}
		if not south {
			n_coords <+ current_cell.coordinate+{1,0};
			if neighbor_type = MOORE {
				n_coords <+ current_cell.coordinate+{1,-1};
				n_coords <+ current_cell.coordinate+{1,1};
			}
		}

		return remove_duplicates(n_coords) collect (grid at (each));
	}
	
	/*
	 * Cells of the grid
	 */
	species cell {
		point coordinate;
		float value;
		list<cell> neighbors(string neighbor_type  <- VONNEUMAN) {return host.neighbors(self,neighbor_type);}
	}
	
	aspect default {
		loop c over:grid {
			draw string(c.value) at:location color:#black;
			draw c color:#transparent border:#black;
		}
	}
	
}
