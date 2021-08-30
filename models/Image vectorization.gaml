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
	float resolution_factor <- 0.4 parameter:true max:1.0;
	float altitude_color_factor<-2.084;
	
	 
	/*
	 * Import the image to vectorize
	 */
/* 	image_file image_mnt <- image_file("../images/mnt_test.png");
	image_file image_truc <- image_file("../images/trucs_test.png");
	image_file image_green<- image_file("../images/green_test.png");
*/
	
	image_file image_autoroute<- image_file("../CityMap/autoroute_route-nationale_4.png");
	image_file image_route<- image_file("../CityMap/autres_routes_4.png");
	image_file image_batiments_river<- image_file("../CityMap/batiments_vallat_4.png");
	image_file image_vert<- image_file("../CityMap/espaces_naturels_mer_4.png");
	image_file image_mnt <- image_file("../CityMap/MNT_4.png");
image_file image_spec_riv<- image_file("../CityMap/spe_riv.png");
	
	bool zone_verte<-false;
	bool batiment_riv<-false;
	bool mnt<-false;
	bool route<-false;
	bool spe_riv<-true;
	
	
	/*
	 * Get the resolution of the image
	 
	int res_x <- matrix(image_truc).columns;
	int res_y <- matrix(image_truc).rows;
	*/
	
	int res_x <- matrix(image_spec_riv).columns;
	int res_y <- matrix(image_spec_riv).rows;
	
	/*
	 * 
	 * Adapt the underlying grid to vectorize and the shape of the world
	 * according to image resolution and the ratio of vectorization
	 * 
	 */
	int g_x <- int(res_x * resolution_factor);
	int g_y <- int(res_y * resolution_factor);	
	int g_x_mnt <- int(g_x/10);
	int g_y_mnt <- int(g_y/10);
	
	
	geometry shape <- rectangle(res_x,res_y);
	map<rgb, list<cell>> cells_per_color;
	map<rgb, list<cell>> cells_per_color_select;

	/*
	 * The color and associated species
	 * WARNING: Model specific
	 */
	/*map<rgb,string> color_to_species <- [
		[247,148,30]::string(highway),[255,242,0]::string(main_road),[102,45,145]::string(city_road),
		[46,49,146]::string(river),[189,190,192]::string(residential_building),
		[57,181,74]::string(green_area),[96,56,19]::(erp),[37,170,225]::(sea), [159,31,99]::(market)
		, [255,255,255]::(background)
	];*/
	
	map<rgb,string> color_to_species <- [
		rgb(#red)::string(bridge),rgb(#green)::string(ground), [255,255,255]::(background)];
	
	float max_value;
	float min_value;
	init {

		float t <- machine_time;
		
		write "START CREATION OF THE ENVIRONMENT";
		
		write "Image resolution : "+string(res_x)+" x "+string(res_y);
		
		/*
		 * Manage resolution ratio
		 */
		float factorDiscret_width <- res_y / g_y;
		float factorDiscret_height <- res_x / g_x;
		
		
		
		 
		
				//***************** cherche le mnts************************
	if mnt{	
						ask cell {		
			color <-rgb( (image_mnt) at {grid_x * factorDiscret_height,grid_y * factorDiscret_width}) ;
			altitude<-(255*3-(color.red+color.green+color.blue))/altitude_color_factor;
			do update_color;
		}
		
		ask cell_mnt {
			list<cell> my_cells <- cell overlapping self;
			//write length(my_cells);
			grid_value<- my_cells max_of(each.altitude);
			write length(grid_value);
		}	
	
	}
	
	
			//***************** cherche les zones vertes************************
	if zone_verte { 	
	 			ask cell {		
			color <-rgb( (image_vert) at {grid_x * factorDiscret_height,grid_y * factorDiscret_width}) ;
		}
		
		
		 cells_per_color <- cell group_by each.color;
		 
		
		write "Found "+length(cells_per_color)+" color in the draw";
		

		loop col over: cells_per_color.keys {
			if length(cells_per_color[col])>10 {
				
			}
			geometry geom <- union(cells_per_color[col]) + 0.001;
			if (geom != nil) {
				
				write "--------";
				rgb best_match;
				list bm <- [255,255,255];
				loop cl over:color_to_species.keys {
					int r <- abs(cl.red-col.red);
					int g <- abs(cl.green-col.green);
					int b <- abs(cl.blue-col.blue);
					if(r+g+b < sum(bm)){
						best_match <- cl;
						bm <- [r,g,b];
					}
				}
				write "Detected color image ["+string(col)+"] has been associated to ["+string(best_match)+"]";

				
				string species_name <- color_to_species[best_match];
				switch species_name {	
					match string(green_area) {
						create green_area from: geom.geometries;
					}
							match string(sea) {
						create sea from: geom.geometries;
					}
								match string(background) {
						create background from: geom.geometries;
					}
				}
			}
		}
		
		}
		
		
		//***************** cherche les batiments et riviere************************
		
		if batiment_riv {
				ask cell {		
			color <-rgb( (image_batiments_river) at {grid_x * factorDiscret_height,grid_y * factorDiscret_width}) ;
		}
		
	
		cells_per_color <- cell group_by each.color;

		
		write "Found "+length(cells_per_color)+" color in the draw";
	
		loop col over: cells_per_color.keys {
		
			geometry geom <- union(cells_per_color[col]) + 0.001;
		

			if (geom != nil) {
				
				write "--------";
				rgb best_match;
				list bm <- [255,255,255];
				loop cl over:color_to_species.keys {
					int r <- abs(cl.red-col.red);
					int g <- abs(cl.green-col.green);
					int b <- abs(cl.blue-col.blue);
					if(r+g+b < sum(bm)){
						best_match <- cl;
						bm <- [r,g,b];
					}
				}
				write "Detected color image ["+string(col)+"] has been associated to ["+string(best_match)+"]";

			
				string species_name <- color_to_species[best_match];
				switch species_name {
						match string(market) {
						create market from: geom.geometries;
					}
						match string(residential_building) {
						create residential_building from: geom.geometries;
					}
					
					match string(erp) {
						create erp from: geom.geometries;
					}
							match string(river) {
						create river from: geom.geometries;
					}
								match string(background) {
						create background from: geom.geometries;
					}
					
				
			}
		}
		}
		
		}
		
		
		//***************** cherche les spe de riviere************************
		
		if spe_riv {
				ask cell {		
			color <-rgb( (image_spec_riv) at {grid_x * factorDiscret_height,grid_y * factorDiscret_width}) ;
		}
		
	
		cells_per_color <- cell group_by each.color;

		
		write "Found "+length(cells_per_color)+" color in the draw";
	
		loop col over: cells_per_color.keys {
		
			geometry geom <- union(cells_per_color[col]) + 0.001;
		

			if (geom != nil) {
				
				write "--------";
				rgb best_match;
				list bm <- [255,255,255];
				loop cl over:color_to_species.keys {
					int r <- abs(cl.red-col.red);
					int g <- abs(cl.green-col.green);
					int b <- abs(cl.blue-col.blue);
					if(r+g+b < sum(bm)){
						best_match <- cl;
						bm <- [r,g,b];
					}
				}
				write "Detected color image ["+string(col)+"] has been associated to ["+string(best_match)+"]";

			
				string species_name <- color_to_species[best_match];
				switch species_name {
						match string(bridge) {
						create bridge from: geom.geometries;
					}
						match string(ground) {
						create ground from: geom.geometries;
					}
					
			
								match string(background) {
						create background from: geom.geometries;
					}
					
				
			}
		}
		}
		
		}
		
		
			//***************** cherche les routes************************
		if route {
			ask cell {		
			color <-rgb( (image_route) at {grid_x * factorDiscret_height,grid_y * factorDiscret_width}) ;
		}
		
	
		cells_per_color <- cell group_by each.color;
		
		write "Found "+length(cells_per_color)+" color in the draw";
	
		loop col over: cells_per_color.keys {
			geometry geom <- union(cells_per_color[col]) + 0.001;
			if (geom != nil) {
				
				write "--------";
				rgb best_match;
				list bm <- [255,255,255];
				loop cl over:color_to_species.keys {
					int r <- abs(cl.red-col.red);
					int g <- abs(cl.green-col.green);
					int b <- abs(cl.blue-col.blue);
					if(r+g+b < sum(bm)){
						best_match <- cl;
						bm <- [r,g,b];
					}
				}
				write "Detected color image ["+string(col)+"] has been associated to ["+string(best_match)+"]";

			
				string species_name <- color_to_species[best_match];
				switch species_name {
			
					match string(city_road) {
						create city_road from: geom.geometries;
					}
	
						match string(background) {
						create background from: geom.geometries;
					}
					
				}
			}
		}
		
		
		
		
		
					//***************** cherche les autoroutes************************
		
			ask cell {		
			color <-rgb( (image_autoroute) at {grid_x * factorDiscret_height,grid_y * factorDiscret_width}) ;
		}
		
	
		cells_per_color <- cell group_by each.color;
		
		write "Found "+length(cells_per_color)+" color in the draw";
	
		loop col over: cells_per_color.keys {
			geometry geom <- union(cells_per_color[col]) + 0.001;
			if (geom != nil) {
				
				write "--------";
				rgb best_match;
				list bm <- [255,255,255];
				loop cl over:color_to_species.keys {
					int r <- abs(cl.red-col.red);
					int g <- abs(cl.green-col.green);
					int b <- abs(cl.blue-col.blue);
					if(r+g+b < sum(bm)){
						best_match <- cl;
						bm <- [r,g,b];
					}
				}
				write "Detected color image ["+string(col)+"] has been associated to ["+string(best_match)+"]";

			
				string species_name <- color_to_species[best_match];
				switch species_name {
			
					match string(highway) {
						create highway from: geom.geometries;
					}
					
					match string(main_road) {
						create main_road from: geom.geometries;
					}
								match string(background) {
						create background from: geom.geometries;
					}
					
				}
			}
		}
		
		}
		
		write "END - TIME ELAPSE: "+((machine_time-t)/1000)+"sec";
		
		write "EXPORT TO FILES";
	/* 	save river to:"../results/river.shp" type:shp;
		save city_road to:"../results/city_road.shp" type:shp;
		save main_road to:"../results/main_road.shp" type:shp;
		save highway to:"../results/highway.shp" type:shp;
		save green_area to:"../results/green.shp" type:shp;
		save residential_building to:"../results/residential_building.shp" type:shp;
		save erp to:"../results/erp.shp" type:shp;
		save market to:"../results/market.shp" type:shp;
		save cell_mnt to:"../results/grid.asc" type:"asc";*/
		save bridge to:"../results/bridge.shp" type:shp;
		save ground to:"../results/ground.shp" type:shp;
		
		
		float altmax<-cell_mnt max_of(each.grid_value); 
		write altmax;
	}
	
}

//definition of the grid from the asc file: the width and height of the grid are directly read from the asc file. The values of the asc file are stored in the grid_value attribute of the cells.

grid cell  width: g_x height: g_y {
	float altitude;
 	rgb my_color;
 	
	
		action update_color {	
		my_color<-rgb(int(min([255,max([245 - 1 *altitude, 0])])), int(min([255,max([245 - 1.5 *altitude, 0])])), int(min([255,max([0,220 - 2.5 * altitude])])));
		grid_value<-altitude;
		
		}
			
	
		aspect default {
			draw shape  color:my_color;

}
}


grid cell_mnt  width: g_x_mnt height: g_y_mnt {
	float altitude;
 	rgb my_color;
 	float grid_value;
		
	
		aspect default {
			draw shape  color:my_color;

}
}







species background{
	aspect default {
		draw shape color: #white;
	}
}


species bridge {
	aspect default {
		draw shape color: #red;
	}
}

species ground {
	aspect default {
		draw shape color: #green;
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
		draw shape color:#red border:#black ;
	}
}

species main_road parent:road {
	aspect default {
		draw shape color:#orange border:#black ;
	}
}

species city_road parent:road {
	aspect default {
		draw shape color:#yellow border:#black ;
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
			
			
			species cell;
			//species background;
			species green_area;
			species river;
			species city_road;
			species main_road;
			species highway;
			species residential_building;
			species erp;
			species market;
			species sea;
			species bridge;
			species ground;
			
			
		}
	 	display image {
		//	image image_truc;
		//	image image_mnt;
		//image image_ville;
		}
	}
}