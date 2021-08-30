/**
* Name: Splitroads
* Based on the internal skeleton template. 
* Author: Patrick Taillandier
* Tags: 
*/

model Splitroads

global {
	shape_file main_roads_shape_file <- shape_file("../../results/main_road.shp");
	shape_file city_roads_shape_file <- shape_file("../../results/city_roads_separees.shp");
	shape_file highway_shape_file <- shape_file("../../results/highway.shp");
	
	geometry shape <- envelope(envelope(main_roads_shape_file)+envelope(city_roads_shape_file)+envelope(highway_shape_file));
	
	float road_limit <- 150 #m;
	
	init {
		create road from: clean_network(city_roads_shape_file.contents accumulate each.geometries, 1.0,true,true) {
			category<-0;
		}


		create road from:split_lines(main_roads_shape_file.contents  accumulate each.geometries) {
			category<-1;
			list<road> roads <- road overlapping self  ;
			if not empty(roads) {
				roads << self;
				list<geometry> gs <- split_lines((road collect each.shape) + [shape], false);
				shape <- shape + 0.5;
				ask roads {
					shape <- shape + 0.5;
				}
				loop g over: gs {
					create road   {
						shape <- g;
						road ref <- (road + [myself]) first_with (each covers g);
						if ref = nil {
							write "bug: " + g;
							category <- 3;
						}
						category <- ref.category;
					}
				}
				ask roads {
					do die;
				}
				do die;
			}
			
		}
		
		
		
		bool end <- false;
		loop while: not end {
			end <- true;
			ask road where (each.shape.perimeter > road_limit) {
				end <- false;
				list<geometry> sub_g <- shape to_sub_geometries([0.5,0.5]);
				shape <- sub_g[0];
				create road with: (shape: sub_g[1], category: category) ;
			}	
		}
		save road to: "../../results/roads.shp" type:shp attributes:["category"];
	}	
}


species road {
	rgb color <- rnd_color(255);
	int category; //0:city, 1:national, 2;highway
	
	aspect default {
		draw shape + (1 + 2 * category) color: color;
	}

}


experiment Splitroads type: gui {
	output {
		display map {
			species road;
		}
	}
}
