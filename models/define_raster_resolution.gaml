/**
* Name: OSM file to Agents
* Author:  Patrick Taillandier
* 
*/
model rasterresolution


global
{

	string output_name <- "LCred4_5m.asc";
	grid_file the_grid_file <- grid_file("../../includes/LCred4.asc");
	float cell_size <- 5.0;
	float max_dist <- 25.0;
	geometry shape <- envelope(the_grid_file);
	init
	{
		write "grid file loaded";
		float max_elevation <- cell max_of each.grid_value;
		float min_elevation <- cell min_of each.grid_value;
		
		ask cell {
			float val <- 255 * (grid_value - min_elevation)/(max_elevation - min_elevation);
			color <- rgb(val,val,val);
		}
		
		write "color for cells defined";
		using topology(world) {
			ask cell_2 parallel: false{
				list<cell> ps <- cell at_distance max_dist;
				float weight; 
				bool division <- true;
				loop p over: ps {
					float dist <- p.location distance_to location;
					if (dist = 0.0) {division <- false; grid_value <-  p.grid_value; break;}
					else {
						grid_value <- grid_value+ (p.grid_value / dist); 
						weight <- weight + (1/dist);
					}
				}
				if (division) {
					grid_value <- grid_value / weight;	
				}
				float val <- 255 * (grid_value - min_elevation)/(max_elevation - min_elevation);
				color <- rgb(val,val,val);
			}
		}
		write "grid value updated";
		save cell_2 to:"../../includes/"+output_name type: asc;
		write "file saved";

	}

}

grid cell_2 cell_width: cell_size cell_height: cell_size;

grid cell file: the_grid_file;



experiment "to resolution" type: gui
{
	output
	{
		display map1 type: opengl
		{
			grid cell ;
		}
		
		display map2 type: opengl
		{
			grid cell_2 ;
		}

	}

}