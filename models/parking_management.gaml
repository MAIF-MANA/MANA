/**
* Name: parkingmanagement
* Based on the internal skeleton template. 
* Author: Patrick Taillandier
* Tags: 
*/

model parkingmanagement

global {
	shape_file city_roads_shape_file <- shape_file("../includes/city_roads.shp");

	shape_file parking_shape_file <- shape_file("../includes/parking.shp");

	shape_file main_road_shape_file <- shape_file("../includes/main_road.shp");

	geometry shape <- envelope(city_roads_shape_file);
	graph road_network;
	init {
		
		create parking from: parking_shape_file;
		//create road from: city_roads_shape_file;
		list<geometry> g_rds <- clean_network(city_roads_shape_file.contents + main_road_shape_file.contents,0.0,true,true);
		loop g over: g_rds {
			list<parking> parkings <- parking overlapping g;
			loop p over: parkings {
				g <- g - p;
				if shape = nil {
					break;
				}
			}
		}
		
		g_rds <- g_rds where (each != nil);
		ask parking {
			list<geometry> gs <- g_rds at_distance 0.5;
			list<point> pts <- gs collect (each closest_points_with self)[0];
			if length(pts) > 1 {
				loop i from: 0 to: length(pts) -2 {
					loop j from: i + 1 to: length(pts) -1 {
						g_rds << line([pts[i], pts[j]]);
					}
				} 
				
			}
		}
		create road from: g_rds;
		road_network <- as_edge_graph(road);
		create car number: 100;
		
	}
}

species parking {
	aspect default {
		draw shape color: #violet;
	}
}

species road {
	aspect default {
		draw shape color: #black;
	}
}

species car skills: [moving] {
	rgb color <- rnd_color(255);
	point target;
	init {
		location <- any_location_in(one_of(parking));
	}
	reflex test_go when: target = nil and flip(0.001) {
		target <- any_location_in(one_of(parking));
	} 
	reflex move when: target != nil {
		do goto target: target on: road_network;
		if location =target {
			target <- nil;
		}
	}
	
	aspect default {
		draw circle(5.0) color: color; 
	}
}

experiment parkingmanagement type: gui {
	output {
		display map {
			species road;
			species parking;
			species car;
			
		}
	}
}
