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
		
		map<geometry,point> cell_coordinates <- squaredgeom as_map (each::each.location);
		
		
		list<float> x_full <- squaredgeom collect (each.location.x);
		list<float> x_coord <- remove_duplicates(x_full);
		//list<float> x_coord_verified <- no_duplicates(squaredgeom collect (each.location.x), 0.01);
		int max_x <- max(x_coord count (x_full contains each));
		
		list<float> y_full <- squaredgeom collect (each.location.y);
		list<float> y_coord <- remove_duplicates(y_full);
		//list<float> y_coord_verified <- no_duplicates(squaredgeom collect (each.location.y), 0.01);
		int max_y <- max(y_coord count (y_full contains each));
		
		m <- {max_x,max_y} matrix_with nil;
		
		if debug_mode {write "Square got "+max_x+" max x coordintate and "+max_y+" max y coordinate";}
		
		loop k over:cell_coordinates.keys {
			put k in:m at:{x_coord index_of cell_coordinates[k].x,
				y_coord index_of cell_coordinates[k].y};
		}
		
		create gridshape returns:gs {
			create cell from:m with:[shape::shape,coordinate::location] returns:cells;
			
		} 
		
		return gs[0];
	}
	
}

/*
 * A grid species based on any geometry
 */
species gridshape {
	
	matrix<cell> grid;
	string neighbor_type init:"vonneuman" among:["moore","vonneuman"];
	
	list<cell> neighbors(cell current_cell, string neighbor_type) {
		list<cell> nghbrs;
		if neighbor_type = VONNEUMAN {
			return [grid at (current_cell.coordinate+{0,1}),
				grid at (current_cell.coordinate+{1,0}),
				grid at (current_cell.coordinate+{0,-1}),
				grid at (current_cell.coordinate+{-1,0})
			];
		} else if neighbor_type = MOORE {
			return [grid at (current_cell.coordinate+{0,1}),
				grid at (current_cell.coordinate+{1,1}),
				grid at (current_cell.coordinate+{1,0}),
				grid at (current_cell.coordinate+{1,-1}),
				grid at (current_cell.coordinate+{0,-1}),
				grid at (current_cell.coordinate+{-1,-1}),
				grid at (current_cell.coordinate+{-1,0}),
				grid at (current_cell.coordinate+{-1,1})
			];
		} else {
			error "no such neighbor type : "+neighbor_type;
		}
	}
	
	/*
	 * Cells of the grid
	 */
	species cell {
		point coordinate;
	}
	
}
