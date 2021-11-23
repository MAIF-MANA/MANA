/***
* Name: EscapeTrainingEnvironment
* Author: pataillandie and kevinchapuis
* Description: Vectorize an image and save result into shapefile
* Tags: Vectorization, image, synthetic environment
***/

model EscapeTrainingEnvironment

global {
	
	/*
	 * How precise the vectorization is
	 */
	 float simplification_dist <- 5.0;
	float size_x <- 3.5#km;
	float size_y <- 2.5#km;
	
	float altitude_color_factor<-2.084;
	
	float max_coeff_dist <- 0.1;
	int num_cols_mnt <- 140;
	int num_rows_mnt <- 100;
	
	
	int power_interpolation <- 1;
	/*
	 * Import the image to vectorize
	 */

//	image_file image_autoroute<- image_file("../../CityMap/autoroute_route-nationale_4.png");
//	image_file image_route<- image_file("../../CityMap/autres_routes_4.png");
//	image_file image_batiments_river<- image_file("../../CityMap/batiments_vallat_4.png");
//	image_file image_vert<- image_file("../../CityMap/espaces_naturels_mer_4.png");
	image_file image_mnt <- image_file("../../CityMap/MNT_5.png");
//	image_file image_mnt <- image_file("../../CityMap/MNT_4.png");

	
	bool zone_verte<-false;
	bool batiment_riv<-false;
	bool mnt<-true;
	bool route<-false;
	
	int res_x <- matrix(image_mnt).columns;
	int res_y <- matrix(image_mnt).rows;
	
	
	geometry shape <- rectangle(size_x,size_y);
	
		
	
 	map<rgb,string> color_to_species <- [
		rgb([247,148,30])::string(highway),rgb([255,242,0])::string(main_road),rgb([102,45,145])::string(city_road),
		rgb([46,49,146])::string(river),rgb([189,190,192])::string(residential_building),
		rgb([57,181,74])::string(green_area),rgb([96,56,19])::string(erp),rgb([37,170,225])::string(sea), rgb([159,31,99])::string(market)
	];
	
		init {

		float t <- machine_time;
		
		write "START CREATION OF THE ENVIRONMENT";
		
		write "Image resolution : "+string(res_x)+" x "+string(res_y);
		
		 
		
				//***************** cherche le mnts************************
	
	
	
		if (mnt) {
			using topology(world) {
				
				ask cell_mnt_extract{
					list<cell> my_cells <- cell overlapping self;
					grid_value<- my_cells mean_of(each.altitude);
					do update_color;
					
				}
				ask  cell_mnt {
					list<cell_mnt_extract> cells <- cell_mnt_extract at_distance (2 * cell_mnt_extract(location).shape.width);
					list<float> dists <- cells collect (each distance_to location);
					dists <- dists collect (each = 0.0 ? max_coeff_dist : min(max_coeff_dist, 1.0/each));
					loop i from: 0 to: length(cells) - 1 {
						grid_value <- grid_value + cells[i].grid_value * dists[i];
					}
					grid_value <- grid_value / sum(dists);
					do update_color;
				}
			}
			
			save cell_mnt to:"../results/grid3.asc" type:"asc";
		}
	
			
		write "mnt generated";
	
	
			//***************** cherche les zones vertes************************
	 
		if zone_verte { 	
	 		do generate_agent("nature");
		}
		
		write "zones vertes generated";
	
		if batiment_riv { 	
	 		do generate_agent("batiment");
		}
		
		write "buildings generated";
	
		if route { 	
	 		do generate_agent("route");
	 		do generate_agent("autoroute");
		}
		
		write "END - TIME ELAPSE: "+((machine_time-t)/1000)+"sec";
		
		write "EXPORT TO FILES";
		
	}
	
	
	action generate_agent(string type) {
		ask cell {
			color <- color_per_type[type];
		}	
		map<rgb, list<cell>> cells_per_color <- cell group_by each.color;
	
		
		loop col over: cells_per_color.keys {
			if col in color_to_species.keys {
				list<geometry> geoms ;
				geometry geom <- union(cells_per_color[col]) + 0.001 ;
				geoms <- geom.geometries;
			
				create species(color_to_species[col]) from: geoms returns: agent_created {
					shape <- shape simplification simplification_dist;
				}
			//	save agent_created type: shp to: "../results/" + (color_to_species[col]) + ".shp";
			}
		}
		
	}	
}



//definition of the grid from the asc file: the width and height of the grid are directly read from the asc file. The values of the asc file are stored in the grid_value attribute of the cells.

grid cell  width: res_x height: res_y {
	float altitude;
 	map<string,rgb> color_per_type;
 	bool is_road <- false;
 	bool done <- false;

}

grid cell_mnt_extract  width: num_cols_mnt / 4 height: num_rows_mnt / 4  {
	action update_color {
 		color <-rgb(int(min([255,max([245 - 1 *grid_value, 0])])), int(min([255,max([245 - 1.5 *grid_value, 0])])), int(min([255,max([0,220 - 2.5 * grid_value])])));
	
 	}
}

grid cell_mnt  width: num_cols_mnt height: num_rows_mnt {
	action update_color {
 		color <-rgb(int(min([255,max([245 - 1 *grid_value, 0])])), int(min([255,max([245 - 1.5 *grid_value, 0])])), int(min([255,max([0,220 - 2.5 * grid_value])])));
	
 	}

}



species river {
	aspect default {
		draw shape color: #blue;
	}
}

species building {
	aspect default {
		draw shape color: #gray border:#black ;
	}
}

species residential_building parent:building {
	aspect default {
		draw shape color: #gray border:#black ;
	}
}

species erp parent:building {
	aspect default {
		draw shape color: #brown border:#black ;
	}
}

species market parent:building {
	aspect default {
		draw shape color: #violet border:#black ;
	}
}


species sea {
		aspect default {
		draw shape color: #blue border:#black ;
	}
}

species road {
	float capacity;
	aspect default {
		draw shape color:#black;
	}
}


species highway parent:road {
	aspect default {
		draw shape color:#red ;
	}
}

species main_road parent:road {
	aspect default {
		draw shape color:#orange  ;
	}
}

species city_road parent:road {
	aspect default {
		draw shape color:#gray  ;
	}
}




species green_area {
	aspect default {
		draw shape color:#green;
	}
}

experiment Vectorize type: gui {
	output {
		
		display map_vector type:opengl{
			grid cell_mnt;
			species green_area ;
			species river;
			species city_road;
			species main_road;
			species highway;
			species residential_building;
			species erp;
			species market;
			species sea;
		}
	}
}