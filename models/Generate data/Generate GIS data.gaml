/***
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
***/

model switch_utilities_gis

global {
	
	
	
	//define the path to the dataset folder
	string dataset_path <- "../../includes/auriol/";

	//define the bounds of the studied area
	file data_file <-shape_file(dataset_path + "zone.shp");
	
	string boundary_name_field <-"NOM_COM_M";  //"nom_comm";
	list<string> residential_types <- ["apartments", "hotel", "Résidentiel"]; 
	
	float simplification_dist <- 1.0;
	//optional
	string osm_file_path <- dataset_path + "map.pbf";
	
	list<string> type_to_specify <- [nil, "yes", ""];
		
	float mean_area_flats <- 200.0;
	float min_area_buildings <- 20.0;
	int nb_for_road_shapefile_split <- 20000;
	int nb_for_node_shapefile_split <- 100000;
	int nb_for_building_shapefile_split <- 50000;
	
	float default_road_speed <- 50.0;
	int default_num_lanes <- 1;
	
	bool display_google_map <- true parameter:"Display google map image";
	bool parallel <- true;
	//-----------------------------------------------------------------------------------------------------------------------------
	
	list<rgb> color_bds <- [rgb(241,243,244), rgb(255,250,241)];
	
	map<string,rgb> google_map_type <- ["restaurant"::rgb(255,159,104), "shop"::rgb(73,149,244)];
	
	geometry shape <- envelope(data_file);
	map filtering <- ["building"::[], "highway"::[], "waterway"::[]];
	image_file static_map_request ;
	init {
		write "Start the pre-processing process";
		create Boundary from: data_file {
			if (boundary_name_field != "") {
				string n <- shape get boundary_name_field;
				if (n != nil and n != "") {
					name <- n;
				}
			}
			if (simplification_dist > 0) {
				shape <- shape simplification simplification_dist;
			}
		}
		
		osm_file osmfile;
		if (file_exists(osm_file_path)) {
			osmfile  <- osm_file(osm_file_path, filtering);
		} else {
			point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
			point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
			string adress <-"http://overpass.openstreetmap.ru/cgi/xapi_meta?*[bbox="+top_left.x+"," + bottom_right.y + ","+ bottom_right.x + "," + top_left.y+"]";
			write "adress: " + adress;
			osmfile <- osm_file<geometry> (adress, filtering);
		}
		
		write "OSM data retrieved";
		list<geometry> geom <- osmfile  where (each != nil);
		list<geometry> roads_intersection <- geom where (each.attributes["highway"] != nil);
		list<geometry> waterways <- geom where (each.attributes["waterway"] != nil) where (each.perimeter > 0);
		
		list<geometry> ggs <- geom where (each != nil and each.attributes["highway"] = nil and each.attributes["waterway"] = nil);
		write "geometries selected";
		int val <- int(length(ggs) / 100);
		
		
		create Waterway from: waterways 
	  {
			shape <- shape simplification simplification_dist ;
		}
		
		save Waterway to:(dataset_path+"/waterways.shp") type: shp;
		
		create Building from: ggs with:[building_att:: get("building"),shop_att::get("shop"), historic_att::get("historic"), 
			office_att::get("office"), military_att::get("military"),sport_att::get("sport"),leisure_att::get("lesure"),
			height::float(get("height")), flats::int(get("building:flats")), levels::int(get("building:levels"))
		]  {
			shape <- shape simplification simplification_dist ;
			id <- int(self);
		}
		write "Building created";
		ask Building {
			list<Boundary> bds <- (Boundary overlapping location);
			if empty(bds){do die;} 
			else {
				boundary <- first(bds);
			}
		}
		
		write "useless buildings removed";
		ask Building where ((each.shape.area = 0) and (each.shape.perimeter = 0)) parallel: parallel {
			list<Building> bd <- Building overlapping self;
			ask bd where (each.shape.area > 0) {
				sport_att  <- myself.sport_att;
				office_att  <- myself.office_att;
				military_att  <- myself.military_att;
				leisure_att  <- myself.leisure_att;
				amenity_att  <- myself.amenity_att;
				shop_att  <- myself.shop_att;
				historic_att <- myself.historic_att;
			}
		}
		write "information from other layers integrated";
		
		ask Building where (each.shape.area < min_area_buildings) {
			do die;
		}
		
		write "small building removed ";
	
		ask Building parallel: parallel{
			if (amenity_att != nil) {
				types << amenity_att;
			} if (shop_att != nil) {
				types << shop_att;
			}
			 if (office_att != nil) {
				types << office_att;
			}
			 if (leisure_att != nil) {
				types << leisure_att;
			}
			 if (sport_att != nil) {
				types << sport_att;
			}  if (military_att != nil) {
				types << military_att;
			}  if (historic_att != nil) {
				types << historic_att;
			}  if (building_att != nil) {
				types << building_att;
			} 
		}
		
		ask Building parallel:parallel {
			types >> "";
		}
		
		write "building type set ";
		
		ask Building where empty(each.types) {
			do die;
		}
		write "building with no type removed";
		
		
		
		ask Building parallel: parallel{
			type <- first(types);
			types_str <- type;
			if (length(types) > 1) {
				loop i from: 1 to: length(types) - 1 {
					types_str <-types_str + "," + types[i] ;
				}
			}
			if (flats = 0) {
				if not empty(residential_types inter types) {
					if (levels = 0) {levels <- 1;}
					flats <- int(shape.area / mean_area_flats) * levels;
				} else {
					flats <- 1;
				}
			}
		}
	
		map<string, list<Building>> buildings <- Building group_by (each.type);
		loop ll over: buildings.values {
			rgb col <- rnd_color(255);
			ask ll parallel: parallel {
				color <- col;
			}
			
		}
		save Building to:(dataset_path+"/buildings.shp") type: shp attributes: ["id"::id,"sub_area"::boundary.name,"type"::type, "types"::types_str , "flats"::flats,"height"::height, "levels"::levels];
							
		
		graph network<- main_connected_component(as_edge_graph(Road));
		ask Road  {
			if not (self in network.edges) {
				do die;
			}
		}
		
		
			
		save Road type:"shp" to:dataset_path +"/roads.shp" attributes:[
				"junction"::junction, "type"::type, "lanes"::self.lanes, "maxspeed"::maxspeed, "oneway"::oneway,
				"foot"::foot, "bicycle"::bicycle, "access"::access, "bus"::bus, "parking_lane"::parking_lane, "sidewalk"::sidewalk, "cycleway"::cycleway] ;
		
		write "road agents saved";
		
	
		//save Road type:"shp" to:dataset_path +"roads.shp" attributes:["junction"::junction, "type"::type, "lanes"::self.lanes, "maxspeed"::maxspeed, "oneway"::oneway] ;
		
		//save Node type:"shp" to:dataset_path +"nodes.shp" attributes:["type"::type, "crossing"::crossing] ;
		 
		do load_satellite_image; 
	}
	
	
	
	action load_satellite_image
	{ 
		point top_left <- CRS_transform({0,0}, "EPSG:4326").location;
		point bottom_right <- CRS_transform({shape.width, shape.height}, "EPSG:4326").location;
		int size_x <- 1500;
		int size_y <- 1500;
		
		string rest_link<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mapSize="+int(size_x)+","+int(size_y)+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		static_map_request <- image_file(rest_link);
	
		write "Satellite image retrieved";
		ask cell {		
			color <-rgb( (static_map_request) at {grid_x,1500 - (grid_y + 1) }) ;
		}
		save cell to: dataset_path +"satellite.png" type: image;
		
		string rest_link2<- "https://dev.virtualearth.net/REST/v1/Imagery/Map/Aerial/?mapArea="+bottom_right.y+"," + top_left.x + ","+ top_left.y + "," + bottom_right.x + "&mmd=1&mapSize="+int(size_x)+","+int(size_y)+ "&key=AvZ5t7w-HChgI2LOFoy_UF4cf77ypi2ctGYxCgWOLGFwMGIGrsiDpCDCjliUliln" ;
		file f <- json_file(rest_link2);
		list<string> v <- string(f.contents) split_with ",";
		int ind <- 0;
		loop i from: 0 to: length(v) - 1 {
			if ("bbox" in v[i]) {
				ind <- i;
				break;
			}
		} 
		float long_min <- float(v[ind] replace ("'bbox'::[",""));
		float long_max <- float(v[ind+2] replace (" ",""));
		float lat_min <- float(v[ind + 1] replace (" ",""));
		float lat_max <- float(v[ind +3] replace ("]",""));
		point pt1 <- CRS_transform({lat_min,long_max},"EPSG:4326", "EPSG:3857").location ;
		point pt2 <- CRS_transform({lat_max,long_min},"EPSG:4326","EPSG:3857").location;
		float width <- abs(pt1.x - pt2.x)/1500;
		float height <- (pt2.y - pt1.y)/1500;
			
		string info <- ""  + width +"\n0.0\n0.0\n"+height+"\n"+min(pt1.x,pt2.x)+"\n"+(height < 0 ? max(pt1.y,pt2.y) : min(pt1.y,pt2.y));
	
		save info to: dataset_path +"satellite.pgw";
		
		
		write "Satellite image saved with the right meta-data";
		 
		
	}
	
	
}


species Waterway {
	aspect default { 
		draw shape color: #blue;	
	}
}


species Road{
	Boundary boundary;
	rgb color <- #red;
	string type;
	string oneway;
	float maxspeed;
	string junction;
	string foot;
	string  bicycle;
	string access;
	string bus;
	string parking_lane;
	string sidewalk;
	string cycleway;
	int lanesforwa;
	int lanesbackw;
	int lanes;
	aspect default {
		draw shape color: color end_arrow: 5; 
	}
	
} 
grid cell width: 1500 height:1500 use_individual_shapes: false use_regular_agents: false use_neighbors_cache: false;


species Building_ign {
	/*nature du bati; valeurs possibles: 
	* Indifférenciée | Arc de triomphe | Arène ou théâtre antique | Industriel, agricole ou commercial |
Chapelle | Château | Eglise | Fort, blockhaus, casemate | Monument | Serre | Silo | Tour, donjon | Tribune | Moulin à vent
	*/
	string NATURE;
	
	/*
	 * Usage du bati; valeurs possibles:  Agricole | Annexe | Commercial et services | Industriel | Religieux | Sportif | Résidentiel |
Indifférencié
	 */
	string USAGE_1; //usage principale
	string USAGE_2; //usage secondaire
	int NOMBRE_DE_; //nombre de logements;
	int NOMBRE_D_E;// nombre d'étages
	float HAUTEUR; 
}
species Building {
	Boundary boundary;
	string type;
	list<string> types;
	string types_str;
	string building_att;
	string shop_att;
	string historic_att;
	string amenity_att;
	string office_att;
	string military_att;
	string sport_att;
	string leisure_att;
	float height;
	int id;
	int flats;
	int levels;
	rgb color;
	aspect default {
		draw shape color: color border: #black depth: (1 + flats) * 3;
	}
}

species Boundary {
	aspect default {
		draw shape color: #gray border: #black;
	}
}

experiment generateGISdata type: gui {
	output {
		display map type: opengl draw_env: false{
			image dataset_path +"satellite.png"  transparency: 0.2 refresh: false;
			species Building;
			species Waterway;
			species Road;
			
		}
	}
}