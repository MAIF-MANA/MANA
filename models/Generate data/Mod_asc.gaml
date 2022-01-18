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

	string output_name <- "grid4.asc";
	file mnt_file <- grid_file("../../results/grid3.asc");
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
			list<cell>	active_cells<-river_cells where (each.grid_x<45 and each.grid_y<25);
			list<cell>	less_active_cells<-river_cells-active_cells;
			ask cell {
				grid_value<-grid_value*250/169;
				
				do update_color;
			}
			
/*			
			
			ask (active_cells where (!each.is_river)) {
			//list<cell>	close_river_cells <- river_cells where (((each.location distance_to self) <= 60#m));		
			close_river_cell <-river_cells closest_to(self);
		//	float min_alt<-close_river_cells min_of(each.grid_value);
			grid_value<-max([grid_value,close_river_cell.grid_value+rnd(20)/10]);
			
			if grid_value<close_river_cell.grid_value {grid_value<-grid_value+3#m;}
			//grid_value<-min([grid_value,min_alt]);
						}
	 */	
		
			
		
		
	 		float prev_alt<-500.0;
	loop riv over:river_cells sort_by (each.location.x*100-each.location.y){
				riv.grid_value<-min([prev_alt,riv.grid_value]);			
				prev_alt<-riv.grid_value;
				ask riv.neighbors where (!each.is_river and each.grid_value>prev_alt) {
					grid_value<-(grid_value+2*prev_alt)/3; 
					already<-true;
					float alt<-grid_value;
					ask neighbors where (!each.is_river and !each.already and each.grid_value>alt) {grid_value<-(grid_value+2*alt)/3;
						float alt2<-grid_value;
						already<-true;
						ask neighbors where (!each.is_river and !each.already and each.grid_value>alt2) {grid_value<-(grid_value+2*alt2)/3;
							float alt3<-grid_value;
							already<-true;
				ask neighbors where (!each.is_river and !each.already and each.grid_value>alt3) {grid_value<-(grid_value+2*alt3)/3;
							float alt4<-grid_value;
							already<-true;
				ask neighbors where (!each.is_river and !each.already and each.grid_value>alt4) {grid_value<-(grid_value+2*alt4)/3;
							already<-true;

				}				
				}				
				}	
				}	
				}
		}
		
			ask cell {already<-false;}
		 	loop riv over:river_cells {
				riv.grid_value<-max([0,riv.grid_value*0.92]);	
				ask riv.neighbors where (!each.is_river and !each.already) {
					grid_value<-max([0,grid_value*0.95]);
					already<-true;
				}
			}
			
				loop riv over:river_cells {
				ask riv.neighbors where (!each.is_river) {
						ask neighbors where (!each.is_river and !each.already) {
					grid_value<-max([0,grid_value*0.98]);
					already<-true;
				}
				}
			}
		
		

		
		
		write "grid value updated";
		save cell to:"../../results/"+output_name type: asc;
		write "file saved";
		write cell max_of(each.grid_value);
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
	bool already;


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
	
	aspect map3D {		
		draw square(sqrt(shape.area)) color:color depth:grid_value ;

	}
	
	}
	
	
	experiment "go" type: gui {
	output {
		display map type: opengl background: #black draw_env: false {
			grid cell ;
			species river refresh: false;

			}
			
				display map3D type: opengl background: #black draw_env: false {
			grid cell  triangulation:false refresh: true ;
			species cell  refresh: true aspect:map3D;				
		}
		}
	}
	
	