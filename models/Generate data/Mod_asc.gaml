/**
* Name: Modasc
* Based on the internal empty template. 
* Author: franck.taillandier
* Tags: 
*/


model Modasc

/* Insert your model definition here */

global {

//***************************  VARIABLES **********************************************************************

	string output_name <- "grid2.asc";
	file mnt_file <- grid_file("../../results/grid.asc");
	shape_file waterways_shape_file <- shape_file("../../results/river.shp");
	geometry shape <- envelope(mnt_file);
	
	init {
			create river from:split_lines(waterways_shape_file.contents) {
			my_cells <- cell overlapping self;
			ask my_cells {
				is_river<-true;
			}
			}
			geometry rivers <- union(river collect each.shape);
			
			list<cell> river_cells<-cell where (each.is_river);
			list<cell>	clo_riv_cells <- cell where (((each.location distance_to rivers) <= 300#m));
			list<cell>	active_cells<-clo_riv_cells where (each.grid_x<36 and each.grid_y<24);
			
			ask cell {do update_color;}
			ask (active_cells where (!each.is_river)) {
			//list<cell>	close_river_cells <- river_cells where (((each.location distance_to self) <= 60#m));		
			close_river_cell <-river_cells closest_to(self);
		//	float min_alt<-close_river_cells min_of(each.grid_value);
			grid_value<-max([grid_value,close_river_cell.grid_value+rnd(20)/10]);
			
			if grid_value<close_river_cell.grid_value {grid_value<-grid_value+3#m;}
			//grid_value<-min([grid_value,min_alt]);
						}
		
		
		
		write "grid value updated";
		save cell to:"../../results/"+output_name type: asc;
		write "file saved";
		
	}
	
	
	
	}
	
	
	species river {
	rgb color <- #blue;
	string type;
	cell cell_origin;
	cell cell_destination;
	list<cell> my_cells;
	float river_height <- 0 #m;
	float altitude;
	point my_location;
	float river_length;
	
	float river_broad;
	float river_depth;

	aspect default {
		draw shape color: color;
	}

}




grid cell neighbors: 8 file: mnt_file {
	bool is_river <- false;
	cell close_river_cell;
	action update_color {
		int val_water <- 0;
		if (is_river) {color<-#blue;}
		else {
		color <- rgb(int(min([255,max([245 - 0.8 *grid_value, 0])])), int(min([255,max([245 - 1.2 *grid_value, 0])])), int(min([255,max([0,220 - 2 * grid_value])])));
		
		}
	
	}
	
		aspect default {
			draw shape  color: color depth:grid_value border: #black;

	}
	
	}
	
	
	experiment "go" type: gui {
	output {
		display map type: opengl background: #black draw_env: false {
			grid cell ;
			species river refresh: false;

			}
		}
	}
	
	