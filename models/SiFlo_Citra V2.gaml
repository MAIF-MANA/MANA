/***
* Name: SiFlo
* Author: Franck Taillandier, Pascal Di Maiolo, Patrick Taillandier, Charlotte Jacquenod, Loïck Rauscher-Lauranceau, Rasool Mehdizadeh
* Description: SiFlo is an ABM dedicated to simulate flood events in urban areas. It considers the water flowing and the reaction of the inhabitants. The inhabitants would be able to perform different actions regarding the flood: protection (protect their house, their equipment and furniture…), evacuation (considering traffic model), get and give information (considering imperfect knowledge), etc. A special care was taken to model the inhabitant behavior: the inhabitants should be able to build complex reasoning, to have emotions, to follow or not instructions, to have incomplete knowledge about the flood, to interfere with other inhabitants, to find their way on the road network. The model integrates the closure of roads and the danger a flooded road can represent. Furthermore, it considers the state of the infrastructures and notably protection infrastructures as dyke. Then, it allows to simulate a dyke breaking.
The model intends to be generic and flexible whereas provide a fine geographic description of the case study. In this perspective, the model is able to directly import GIS data to reproduce any territory. The following sections expose the main elements of the model.

* Tags: Flood simulation, Agent based Model, Inhabitant behavior, BDI, emotion, norms
***/
model SiFLo

//***********************************************************************************************************
//***************************  GLOBAL **********************************************************************
//***********************************************************************************************************
global {

//***************************  VARIABLES **********************************************************************

	file mnt_file <- grid_file("../results/grid2.asc");
	file my_data_flood_file <- csv_file("../includes/data_flood3.csv", ",");
	file my_data_rain_file <- csv_file("../includes/data_rain.csv", ",");
	shape_file res_buildings_shape_file <- shape_file("../results/residential_building.shp");
	shape_file market_shape_file <- shape_file("../results/market.shp");
	shape_file erp_shape_file <- shape_file("../results/erp.shp");
	shape_file main_roads_shape_file <- shape_file("../results/main_road.shp");
	shape_file roads_shape_file <- shape_file("../results/city_roads.shp");
	shape_file highway_shape_file <- shape_file("../results/highway.shp");
	shape_file waterways_shape_file <- shape_file("../results/river.shp");
	shape_file green_shape_file <- shape_file("../results/green_area.shp");
	shape_file sea_shape_file <- shape_file("../results/sea.shp");
	shape_file bridge_shape_file <- shape_file("../results/passage_pont.shp");
	shape_file ground_shape_file <- shape_file("../results/riviere_enterree.shp");
	shape_file wall_shape_file <- shape_file("../results/dikes_murets_classes.shp");
	shape_file rain_net_shape_file <- shape_file("../results/pluvial_network.shp");
	shape_file parking_shape_file <- shape_file("../results/parking.shp");
	shape_file plu_nat_shape_file <- shape_file("../results/PLU_N.shp");
	shape_file plu_a_urb_shape_file <- shape_file("../results/PLU_AU.shp");
	shape_file plu_agri_shape_file <- shape_file("../results/PLU_A.shp");
	shape_file natura_shape_file <- shape_file("../results/NATURA_2000.shp");
	
	
	//shape file actions
	shape_file bassin_shape_file <- shape_file("../results/bassin_retention.shp");
	shape_file barrage_shape_file <- shape_file("../results/barrage.shp");
	shape_file extension_nat_shape_file <- shape_file("../results/extention_PLU_N.shp");
	shape_file noue_shape_file <- shape_file("../results/noues_routes.shp");
	
	
	
	date starting_date <- date([2022,1,2,14,0,0]);
	date time_flo;
	
	//shape_file population_shape_file <- shape_file("../includes/city_environment/population.shp");
	geometry shape <- envelope(mnt_file);


	
	map<list<int>,	graph> road_network_custom;
	map<road, float> current_weights;
	graph road_network_simple;
	
	river river_origin;
	river river_ending;
	int increment;
	matrix data_flood;
	matrix data_rain; 
	list<building> obstacles;
	float obstacle_height <- 0.0;
	float ratio_received_water;
	float cell_area;
	int nb_people_begin;

	float max_vulnerability_building_decrease <- 0.6;
	float max_impermeability_building_increase <- 0.2;
	bool display_river <- true;
	bool display_water <- true;
	float max_distance_to_river <-5000#m;
	float time_step <- 30 #sec; //0.2#mn;  
	
	bool first_flood_turn<-false;	
		
	float water_height_perception <- 5 #cm;
	float water_height_danger_inside_energy_on <- 50 #cm;
	float water_height_problem <- 10 #cm;
	float water_height_danger_inside_energy_off <- 80 #cm;

	float river_broad_maint <- 1 #m;
	float river_depth_maint<- 1 #m;
	float river_broad_normal<- 1#m;
	float river_depth_normal<-1#m;
	

	bool end_simul<-false;
	int leaving_people <- 0;

	bool mode_flood<-false;
	
	list<cell> flooded_cell;
	int nb_flooded_cell;

	list<cell> escape_cells;
	list<cell> river_cells;
	
	
	list<road> safe_roads ;
	
	float cumul_water_enter;
			
	string nb_blesse;
	string nb_mort;
	
	float time_simulation<-3#h;
	
	float water_input_average<-10*10^4#m3/#h;
	float time_start_water_input<-0#h;
	float time_last_water_input<-3#h;
	int water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
	
	float rain_intensity_average<-1 #cm;
	float time_start_rain<-0.5#h;
	float time_last_rain<-1#h;
	int rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
	
	list<float> rain_intensity;
	list<float> water_input_intensity;
	
	int flo_str<-2; 	//0: petite à 5 : très fort 
	list<int> scen_flo<-[2,3,1,5];
	int incr_flo<-0;
	
	float default_plu_net<-0.1#m3/#s;
	
	bool scen<-false;      //active ou desactive l'écran de selection des scnéario
	bool creator_mode<-true;
	bool only_flood<-false;
	bool nothing_more<-false;

	
	bool plu_mod<-false;
	list<rgb> color_category <- [#darkgrey, #gold, #red];

	int flooded_building<-0;
	float average_building_state;
	float max_water_he<-0.0;
 

//******************indicateurs et critères *******************
//indicateurs Attractivité
float densite; //pas utilisé pour l'instant
float cout_vie;
float invest_espace_public;

int services;
float entretien_reseau_plu<-0.2;

int commerces;


//indicateurs Sécurité
int dead_people;
int injuried_people;

int flooded_building_erp;
float routes_inondees;

int flooded_building_prive;
int flooded_car;
float bien_endommage;


//indicateurs DD
float taux_artificilisation;

float satisfaction;

float empreinte_carbone;
float ratio_espace_vert;
float biodiversite;
float taux_budget_env;



//poids indicateurs
int W_invest_espace_public<-1;
int W_cout_vie<-2;

int W_entretien_reseau_plu<-1;
int W_services<-1;

int W_dead_people<-10;
int W_injuried_people<-1;

int W_flooded_building_erp<-1;
int W_routes_inondees<-1;

int W_flooded_building_prive<-1;
int W_flooded_car<-1;
int W_bien_endommage<-1;

int W_empreinte_carbone<-2;
int W_ratio_espace_vert<-1;
int W_biodiversite<-2;
int W_taux_budget_env<-1;

//critere
int Crit_logement<-2; //0: nul à 5 : top
int Crit_logement1; //0: nul à 5 : top
int Crit_logement2; //0: nul à 5 : top
int Crit_infrastructure<-2; //0: nul à 5 : top
int Crit_infrastructure1; //0: nul à 5 : top
int Crit_infrastructure2; //0: nul à 5 : top
int Crit_economie<-2;

int Crit_bilan_humain<-3;
int Crit_bilan_humain1;
int Crit_bilan_humain2;
int Crit_bilan_materiel_public<-3;
int Crit_bilan_materiel_public1;
int Crit_bilan_materiel_public2;
int Crit_bilan_materiel_prive<-3;
int Crit_bilan_materiel_prive1;
int Crit_bilan_materiel_prive2;
int Crit_bilan_materiel_prive3;

int Crit_sols<-2;
int Crit_satisfaction<-2;
int Crit_environnement<-2; //0: nul à 5 : top
int Crit_environnement1;
int Crit_environnement2;
int Crit_environnement3;
int Crit_environnement4;


//jeux
int budget_total<-100;
int budget_espace_public<-15;
int budget_env<-10;


//***************************  PREDICAT and EMOTIONS  ********************************************************

	
	list<road> not_usable_roads update: [];
	
	bool parallel_computation <- false;
	
	
	//Variables linked to benchmark
	map<string,float> time_taken_main;
	map<string,float> time_taken_sub;
	float display_every <- 5.0 * time_step;
	float init_time <- machine_time;
	
	//emotion
	emotion fear <- new_emotion("fear");
	
	
	
	
	//********************* RADAR ********************************
	
	list<geometry> axis3 <- define_axis3();
	list<geometry> axis4 <- define_axis4();
	
	int val_min <- 0;
	int val_max <- 5;
	list<string> axis_labelDD <- ["Gestion des sols", "Satisfaction des populationss", "Environement"];
	list<string> axis_labelSec <- ["Bilan humain", "Bilan matériel privé", "Bilan matériel public"];
	list<string> axis_labelAtt <- ["Logement", "Infrastructure", "Economie"];
	float marge <- 0.1;
	int rad_nb<-1;   //1: DD, 2: Sec, 3: Att
	
	list<geometry> define_axis3 {
		list<geometry> gs;
		float angle_ref <- 360 / 3;
		float marge_dist <- world.shape.width * marge;
		loop i from: 0 to:2 {
			geometry g <- (line({0, world.shape.height / 2}, {0, marge_dist}) rotated_by (i * angle_ref));
			g <- g at_location (g.location + world.location - first(g.points));
			gs << g;
		}
		return gs;
	}

	list<point> define_surface3 (list<float> values) {
		list<point> points;
		loop i from: 0 to: 2 {
			float prop <- (values[i] - val_min) / (val_max - val_min);
			points << first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * prop;
		}
		return points;
	}
	
	
		list<geometry> define_axis4 {
		list<geometry> gs;
		float angle_ref <- 360 / 4;
		float marge_dist <- world.shape.width * marge;
		loop i from: 0 to:3 {
			geometry g <- (line({0, world.shape.height / 2}, {0, marge_dist}) rotated_by (i * angle_ref));
			g <- g at_location (g.location + world.location - first(g.points));
			gs << g;
		}
		return gs;
	}
	
		list<point> define_surface4 (list<float> values) {
		list<point> points;
		loop i from: 0 to: 3 {
			float prop <- (values[i] - val_min) / (val_max - val_min);
			points << first(axis4[i].points) + (last(axis4[i].points) - first(axis4[i].points)) * prop;
		}
		return points;
	}
	
	
	
		//***************************  INIT **********************************************************************
	init {
		float t;
		step <-  time_step; 
		ratio_received_water <- 1.0;
		time_flo<-starting_date;
		
		do create_buildings_roads;
		do create_project;
		create institution;
		
		do create_natural_environment;
		do initiate_plu;
		
		ask cell {
			do update_color;
			cell_area<-shape.area;
		}
		

		data_flood <- matrix(my_data_flood_file);
		data_rain <- matrix(my_data_rain_file);
		river_origin <- (river with_min_of (each.location.x));
		river_ending <- (river with_max_of (each.location.x));
	
		do init_cells_and_bd_select;
	

		
		//empty(active_cells overlapping each);
		
		road_network_custom[list<int>([])] <- (as_edge_graph(road) use_cache false) with_shortest_path_algorithm #NBAStar;
		current_weights <- road as_map (each::each.shape.perimeter);
		
		road_network_simple<-as_edge_graph(road);
		//	create people from: population_shape_file; 
		//	write length(building where (each.category=0));

		do create_people;		
		

	}
	
	
		action create_project {
		create project from: bassin_shape_file
		{
			type<-0;
			shape<-scaled_by(shape,0.98); //juste pour réduire un peu la taille pour que ça reste dans le périmètre fixé sans déborder sur la route
			depth<-2#m;
			volume<-depth*shape.area*0.8;
		}
		
		create project from: barrage_shape_file
		{
			type<-1;
			shape<-scaled_by(shape,0.98); 
					}
		
		create project from: extension_nat_shape_file
		{
			type<-2;
			shape<-scaled_by(shape,0.98); 
		}
		
			create project from: noue_shape_file 
		{
			type<-3;
			shape<-scaled_by(shape,0.98); 
		}
		

		
		}
	
	
	action create_buildings_roads {
		create building from: res_buildings_shape_file {
			category<-0;
			if not (self overlaps world) {
				do die;
			}

		}
		
		
		create building from: market_shape_file {
			category<-1;
			if not (self overlaps world) {
				do die;
				
			}

		}
		
		create building from: erp_shape_file {
			category<-2;
			if not (self overlaps world) {
				do die;
			}

		}
		ask building parallel: parallel_computation{
			my_cells <- cell overlapping self;
			ask my_cells {
				add myself to: my_buildings;
				myself.my_neighbour_cells <- (myself.my_neighbour_cells + neighbors);
			}
			if category=0 {my_color <- #grey;}
			if category=1 {my_color <- #yellow;}
			if category=2 {my_color <- #violet;}
			my_neighbour_cells <- remove_duplicates(my_neighbour_cells);
			altitude <- (my_cells mean_of (each.altitude));
			my_location <- location + point(0, 0, altitude + 1 #m);
		}
		
		
				create parking from: parking_shape_file {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells{
				is_parking<-true;
			}
		}
		
		

		
		
		create pluvial_network from: rain_net_shape_file{
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-default_plu_net;
			}
		}
		
		
		
		
		create road from: roads_shape_file{
			category<-0;
			color<-color_category[category];
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
		}
				create road from: main_roads_shape_file{
			category<-1;
			color<-color_category[category];
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
		}
		 
		 create road from: highway_shape_file{
			category<-2;
			color<-color_category[category];
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
		}
		 
		 
		 
	list<geometry> g_rds <- clean_network(roads_shape_file.contents + main_roads_shape_file.contents,0.0,true,true);
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
		road_network_simple <- as_edge_graph(road);
		 
		 		 
	create obstacle from: wall_shape_file{
			ask cell overlapping self {
					is_dyke<-true;
					dyke_height<-myself.height;
			}
		}
		 
		 
	}
	
	action add_data_benchmark(string id, float val) {
		if not (id in time_taken_main.keys) {
			time_taken_main[id] <- val;
		} else {
			time_taken_main[id] <- time_taken_main[id] + val;
		}
	}
	
	action add_data_benchmark_sub(string id, float val) {
		if not (id in time_taken_sub.keys) {
			time_taken_sub[id] <- val;
		} else {
			time_taken_sub[id] <- time_taken_sub[id] + val;
		}
	}
	action create_natural_environment{
		create green_area from: green_shape_file {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells {
				add myself to: my_green_areas;
				
			}
		}
		
		create natura from: natura_shape_file {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells {
				is_natura<-true;
				
			}
		}
		
		
		create sea from: sea_shape_file {
			if not (self overlaps world) {
				do die;
			}
			list<cell> my_cells <- cell overlapping self;
			ask my_cells where !each.is_parking {
				is_sea<-true;
				
			}
		}
		
	
			
		create river from:split_lines(waterways_shape_file.contents) {
			if not (self overlaps world) {
				do die;
			}
			
	
			

			my_cells <- cell overlapping self;
			ask my_cells {
				add myself to: my_rivers;
				add self to:river_cells;
				
			}
			
			altitude <- (my_cells mean_of (each.altitude));
			my_location <- location + point(0, 0, altitude + 1 #m);
			cell_origin <- (my_cells with_max_of (each.altitude));
			cell_destination <- (my_cells with_min_of (each.altitude));
			river_length <- shape.perimeter;
			ask my_cells {
				water_height <- myself.river_height;
				is_river <- true;
			}

		}
		
		
			float prev_alt<-500#m;
	 	loop riv over:river_cells sort_by (each.location.x*100-each.location.y){
				riv.river_broad<-river_broad_normal;
				riv.altitude<-min([prev_alt,riv.altitude]);			
				prev_alt<-riv.altitude;
				ask riv.neighbors where (!each.is_river and each.altitude>prev_alt) {
					altitude<-(altitude+2*prev_alt)/3; 
					already<-true;
					float alt<-altitude;
					ask neighbors where (!each.is_river and !each.already and each.altitude>alt) {altitude<-(altitude+2*alt)/3;
						float alt2<-altitude;
						already<-true;
						ask neighbors where (!each.is_river and !each.already and each.altitude>alt2) {altitude<-(altitude+2*alt2)/3;
							float alt3<-altitude;
							already<-true;
				ask neighbors where (!each.is_river and !each.already and each.altitude>alt3) {altitude<-(altitude+2*alt3)/3;
							float alt4<-altitude;
							already<-true;
				ask neighbors where (!each.is_river and !each.already and each.altitude>alt4) {altitude<-(altitude+2*alt4)/3;
							already<-true;
				
				}
						
				}
						
				}
				
				
				}
				
				}
		}
		
		prev_alt<-500#m;
		loop riv over:river_cells sort_by (each.location.x*100-each.location.y){
				riv.river_altitude<-max([0,min([riv.altitude-river_depth_normal,prev_alt-10#cm])]);
				riv.river_depth<-riv.altitude-riv.river_altitude;
				prev_alt<-riv.river_altitude;
		}
		
		
	}
	
	action create_spe_riv {
		create spe_riv from: bridge_shape_file {
				category<-0;
				list<cell> cell_impacted;
				cell_impacted<-cell where (each.is_river);
				cell_impacted<-cell_impacted where (self overlaps each);
				ask cell_impacted {
					river_depth<-river_depth/1;
					river_broad<-river_broad/2;
				}
			}

			create spe_riv from: ground_shape_file {
				category<-1;
						category<-0;
				list<cell> cell_impacted;
				cell_impacted<-cell where (each.is_river);
				cell_impacted<-cell_impacted where (self overlaps each);
				ask cell_impacted {
					river_depth<-river_depth/2;
					river_broad<-river_broad/1;
					}
			
		}
		}
		
		action initiate_plu {
		// 0: urbain, 1: a urbaniser, 2:agricole, 3:nat, 4:mer 
		create PLU from:plu_a_urb_shape_file {category<-1;}
		create PLU from:plu_agri_shape_file {category<-2;}
		create PLU from:plu_nat_shape_file {category<-3;}

	
		ask PLU  {
			ask cell overlapping self {
				plu_typ<-myself.category;
			}
		}
		ask cell where each.is_sea {
			plu_typ<-4;
		}
		
		
	}
	
	action init_cells_and_bd_select {
		ask cell parallel: parallel_computation {
			if altitude < 0 {
				is_sea <- true;
			} 
			if name="cell2692" or name="cell1829"{
				altitude<-altitude+4#m;
			}
			my_buildings <- remove_duplicates(my_buildings);
			escape_cell <- false;
			if grid_x < 10 {
				escape_cell <- true;
			}
		}
		
		
		escape_cells <- cell where each.escape_cell;
	

		geometry rivers <- union(river collect each.shape);
		using topology(world) {
			ask cell {
				is_active <- true;
			}
		}

		safe_roads <-road where ((each distance_to rivers) > 100#m );
	}
	
	action create_people {
		ask building where (each.category=0) {
			float it_max<-shape.area/50;
			int it<-0;
			
			loop while: it<it_max {
			create people {
				know_flood_is_coming<-flip(informed_on_flood);
				know_rules<-flip(informed_on_rules);
				my_building<-myself;
				starting_at_home<-flip(0.7);
				if know_flood_is_coming {starting_at_home<-true;}
				 if starting_at_home {
				 	location<-any_location_in(myself.location);
				 }
				 else {location<-any_location_in(one_of(building where (each.category>0))).location;				 	
				 }
				
				current_stair <- rnd(my_building.nb_stairs);
				if flip(0.1) {
					doing_agenda<-true;
					if starting_at_home{my_destination_building<- (one_of(building where (each.category>0)));}
					else {my_destination_building<-myself;}
					final_target <-my_destination_building.location;
				}
				
				have_car <- false;
				if flip(0.8) {
				have_car <- true;
				create car {
					my_owner <- myself;
					myself.my_car <- self;
					location <- myself.location;
					float dist <- 100 #m;
					using topology(world) {

						list<parking> park_close<-parking where !each.is_full at_distance 300#m;
						loop prk over:park_close {
							if !is_parked {
								add self to:prk.my_cars;
								prk.nb_cars<-prk.nb_cars+1;
								is_parked<-true;
							//	location <-any_location_in(prk);
								if prk.nb_cars=prk.capacity {prk.is_full<-true;}
							}
						}
						if !is_parked {
						list<road> roads_neigh <- (road where (each.category<2) at_distance dist);
						loop while: empty(roads_neigh) {
							dist <- dist + 50;
							roads_neigh <- (road at_distance dist);
						}
						road a_road <- roads_neigh[rnd_choice(roads_neigh collect each.shape.perimeter)];
						location <- any_location_in(a_road);
						my_owner.heading <- first(a_road.shape.points) towards last(a_road.shape.points);
						is_parked<-true;
						}
						}	
				}	
			
			
	
					
				}
			
			
			}
			it<-it+1;	
			}
			
			}
		
		
				ask parking {
			ask my_cars {is_parked<-false;}
			int cars<-length(my_cars where (!each.is_parked));
			loop g over: to_squares(shape, 4#m, false) {
				 if cars>0 {
					ask one_of(my_cars where (!each.is_parked)) {
						is_parked<-true;
						location <- g.location;
						cars<-cars-1;
						}
					}
				}
				
				
				}	
		
		
		
		
		
		}
		
		action scen_flo {
		flo_str<-scen_flo[incr_flo];
		
		if flo_str=0 {
			time_simulation<-2#h;
			
			water_input_average<-10*10^3#m3/#h;
			time_start_water_input<-0.25#h;
			time_last_water_input<-1.5#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			rain_intensity_average<-0.5 #cm;
			time_start_rain<-0#h;
			time_last_rain<-1#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
		} 
		
			if flo_str=1 {
			time_simulation<-2#h;
			
			water_input_average<-30*10^3#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			rain_intensity_average<-1 #cm;
			time_start_rain<-0.25#h;
			time_last_rain<-1#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
		} 
			 
			 
			 if flo_str=2 {
			time_simulation<-3#h;
			
			water_input_average<-35*10^3#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2.5#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			rain_intensity_average<-1 #cm;
			time_start_rain<-0#h;
			time_last_rain<-2#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			}
			
			if flo_str=3 {
			time_simulation<-3#h;
			
			water_input_average<-100*10^3#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-3#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			rain_intensity_average<-0.2 #cm;
			time_start_rain<-0#h;
			time_last_rain<-3#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			}
			
			 
				if flo_str=4 {
			time_simulation<-3#h;
			
			water_input_average<-60*10^3#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2.5#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			rain_intensity_average<-1.5 #cm;
			time_start_rain<-0#h;
			time_last_rain<-2#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
		} 

	
 
		}
		
//***************************  END of INIT     **********************************************************************


	//***************************  REFLEX GLOBAL **********************************************************************
	float time_start;
	
	string date_in;
	reflex mode {
	if mode_flood {
		time_flo<- current_date;
		date_in<-string(time_flo, "HH:mm:ss");
		if first_flood_turn=true {
			write "Phase d'inondation";
			first_flood_turn<-false;
			loop i from:0 to:int(time_last_rain/step) {
				add rain_intensity_average to:rain_intensity;
			}
			loop i from:0 to:int(time_last_water_input/step) {
				add water_input_average to:water_input_intensity;
			}
		}
		nb_blesse<-"Nombre de blessés : "+string(injuried_people);
		nb_mort<-"Nombre de morts : "+string(dead_people);
		
		if (time mod 30#mn) = 0 {do garbage_collector;}   //every(30 #mn)
		do flower;
		do update_road;
		
		
		max_water_he<-max([max_water_he,cell max_of(each.water_height)]);
		ask cell where (each.water_height=max_water_he) {
		//	write name+" : "+max_water_he;
		}
		
		if (time=time_start+time_simulation) {
			mode_flood<-false;
			write "Morts : "+dead_people;
			write "Blessés : "+injuried_people;
			write ("number of flooded car : " +length(car where (each.domaged)));
			write ("number of flooded building: " +length(building where (each.serious_flood)));
			write ("max hauteur d'eau : " +max_water_he);
			ask project {write "remplissage bassin : "+water_into/volume;}
			do update_indicators; 
			do pause;
			ask cell {
				water_volume<-0.0;
				do compute_water_altitude;	
			}
			
		}
		
	}	
	
	if !mode_flood {
		time_flo<-time_flo+1 #y;
		nb_blesse<-"";
		nb_mort<-"";
		date_in<-string(time_flo.year);
		do reinitiate_indicators;
		write ("Phase de gestion");
		do pause;
		mode_flood<-true;
		time_start<-time;
		first_flood_turn<-true;
		do scen_flo;
		incr_flo<-incr_flo+1;
	}
	
	}
	
	
	action garbage_collector  {
		ask experiment {do compact_memory;}
	}
	
	
	
	



action flower {
ask cell where (each.water_height>1#cm and each.is_pluvial_network) {
	water_volume<-max([0,water_volume-water_evacuation_pl_net*step]);
}
ask cell where (length(each.neighbors)<8) {
water_volume<-max([0,water_volume*length(neighbors)/8]);
}
do flowing2;
ask cell where (each.is_dyke and each.water_height>1#m) {do breaking_dyke;}

}


action flowing2 {
		int incre<-0;
			
			
			ask cell where !each.is_sea parallel: parallel_computation {
				if time>=time_start+time_start_rain and time-time_start-time_start_rain<time_last_rain
				{
					water_volume<-water_volume+rain_intensity[incre]*cell_area*step/1#h;
				}
				
			}
		
			if time>=time_start+time_start_water_input and time-time_start-time_start_water_input<time_last_water_input {
		 	ask river_origin {
				ask cell_origin  parallel: parallel_computation{
					cumul_water_enter<-cumul_water_enter+water_input_intensity[incre];	
					water_volume<-water_volume+water_input_intensity[incre];
					do compute_water_altitude;			
					}	
				}
			}			
		if (time mod 15#mn) = 0 {incre<-incre+1;} 				
		
		ask car parallel: parallel_computation{
			do define_cell;
		}
		ask building parallel: parallel_computation {
			neighbour_water <- false ;
			water_cell <- false;
		}
		ask people where not each.inside parallel: parallel_computation {
			my_current_cell <- cell(location);
		}

			ask cell parallel: parallel_computation{
				if water_volume<=0.0 {already <- true;}
				else {
					already <- false;
					do compute_water_altitude;
			}
			}
			
		
			list<cell> flowing_cell <- cell where (each.water_volume>1 #m3);
		//	list<cell> cells_ordered <- flowing_cell sort_by (each.water_altitude);
			list<cell> cells_ordered <- flowing_cell sort_by (each.altitude);
			ask cells_ordered {do flow2;}
			ask project{do making;}
			ask remove_duplicates((cell where (each.water_height > 0)) accumulate each.my_buildings) parallel: parallel_computation{do update_water;}
			ask car parallel: parallel_computation{do update_state;}
			ask road parallel: parallel_computation{do update_flood;}
			flooded_cell<-remove_duplicates(flooded_cell);
	
				
		
		
		ask building  parallel: parallel_computation {do update_water_color;}
			
		
		float max_wh_bd <- max(building collect each.water_height);
		float max_wh <- max(cell collect each.water_height);
		ask cell  parallel: parallel_computation {do update_color;}
	}
	
	

	action update_road {
		road_network_simple<-as_edge_graph(road where each.usable);
		current_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
	}
	
	action update_road_work {
		geometry rivers <- union(river collect each.shape);
		safe_roads <-road where ((each distance_to rivers) > 100#m );
		road_network_custom[list<int>([])] <- (as_edge_graph(road) use_cache false) with_shortest_path_algorithm #NBAStar;
		road_network_simple<-as_edge_graph(road);
		
		current_weights <- road as_map (each::each.shape.perimeter);
	}



action update_indicators {
	//******************indicateurs *******************

densite<-length(people)/world.shape.area;
cout_vie<-(building where (each.category=0)) mean_of(each.prix_moyen)/length(people);
invest_espace_public<-budget_espace_public/budget_total; //augmente quand inv dans espace public
services<-length(building where (each.category=2));
entretien_reseau_plu<-0.10; //Linéaire de réseau entretenu divisé par le linéaire total, multiplié par 100 (par action à chaque tour)
commerces<-length(building where (each.category=1));

flooded_building_erp<-length(building where (each.serious_flood and each.category=2));
routes_inondees<-road where (each.is_flooded) sum_of(each.shape.perimeter)/road sum_of(each.shape.perimeter);
flooded_building_prive<-length(building where (each.serious_flood and each.category<2));
bien_endommage<-1-mean(building collect each.state); //à calculer
flooded_car<-length(car where (each.domaged));



taux_artificilisation<-(building sum_of (each.shape.area)+parking sum_of (each.shape.area)+road sum_of (each.shape.perimeter*4#m))/world.shape.area;
satisfaction<-people mean_of(each.satisfaction);
empreinte_carbone<-0.5;
ratio_espace_vert<-length(cell  where (each.plu_typ=2))/length(cell  where (each.plu_typ=0));
biodiversite<-(length(cell  where (each.plu_typ=3))+0.2*length(cell  where (each.plu_typ=2)))/length(cell); // à modifier
taux_budget_env<-budget_espace_public/budget_total;    //augmente quand inv dans env





//****************critere ******************


if cout_vie<0.1 {Crit_logement1<-5;}
else {if cout_vie<0.13 {Crit_logement1<-4;}
	else {if cout_vie<0.15 {Crit_logement1<-3;}
		else {if cout_vie<0.18 {Crit_logement1<-2;}
			else {if cout_vie<0.20 {Crit_logement1<-1;}
				else {Crit_logement1<-0;}
			}
		}
}
}
if invest_espace_public<0.08 {Crit_logement2<-0;}
else {if invest_espace_public<0.13 {Crit_logement2<-1;}
	else {if invest_espace_public<0.18 {Crit_logement2<-2;}
		else {if invest_espace_public<0.22 {Crit_logement2<-3;}
			else {if invest_espace_public<0.3 {Crit_logement2<-4;}
				else {Crit_logement2<-5;}
			}
		}
}
}

Crit_logement<-round((Crit_logement1*W_cout_vie+Crit_logement2*W_invest_espace_public)/(W_cout_vie+W_invest_espace_public));


if services<20 {Crit_infrastructure1<-0;}
else {if services<25 {Crit_infrastructure1<-1;}
	else {if services<30 {Crit_infrastructure1<-2;}
		else {if services<35 {Crit_infrastructure1<-3;}
			else {if services<40{Crit_infrastructure1<-4;}
				else {Crit_infrastructure1<-5;}
			}
		}
}
}
if entretien_reseau_plu<0.04 {Crit_infrastructure2<-0;}
else {if entretien_reseau_plu<0.07 {Crit_infrastructure2<-1;}
	else {if entretien_reseau_plu<0.12 {Crit_infrastructure2<-2;}
		else {if entretien_reseau_plu<0.15 {Crit_infrastructure2<-3;}
			else {if entretien_reseau_plu<0.2 {Crit_infrastructure2<-4;}
				else {Crit_infrastructure2<-5;}
			}
		}
}
}
Crit_infrastructure<-round((Crit_infrastructure1*W_services+Crit_infrastructure2*W_entretien_reseau_plu)/(W_services+W_entretien_reseau_plu));


if commerces<250 {Crit_economie<-0;}
else {if commerces<270 {Crit_economie<-1;}
	else {if commerces<280 {Crit_economie<-2;}
		else {if commerces<290 {Crit_economie<-3;}
			else {if commerces<330{Crit_economie<-4;}
				else {Crit_economie<-5;}
			}
		}
}
}




if dead_people=0 {Crit_bilan_humain1<-5;}
else {if dead_people=1 {Crit_bilan_humain1<-4;}
	else {if dead_people<3 {Crit_bilan_humain1<-3;}
		else {if dead_people<5 {Crit_bilan_humain1<-2;}
			else {if dead_people<20 {Crit_bilan_humain1<-1;}
				else {Crit_bilan_humain1<-0;}
			}
		}
}
}
if injuried_people=0 {Crit_bilan_humain2<-5;}
else {if injuried_people<3 {Crit_bilan_humain2<-4;}
	else {if injuried_people<10 {Crit_bilan_humain2<-3;}
		else {if injuried_people<50 {Crit_bilan_humain2<-2;}
			else {if injuried_people<100 {Crit_bilan_humain2<-1;}
				else {Crit_bilan_humain2<-0;}
			}
		}
}
}
Crit_bilan_humain<-round((Crit_bilan_humain1*W_dead_people+Crit_bilan_humain2*W_injuried_people)/(W_dead_people+W_injuried_people));

if flooded_building_erp=0 {Crit_bilan_materiel_public1<-5;}
else {if flooded_building_erp=1 {Crit_bilan_materiel_public1<-4;}
	else {if flooded_building_erp<5 {Crit_bilan_materiel_public1<-3;}
		else {if flooded_building_erp<10 {Crit_bilan_materiel_public1<-2;}
			else {if flooded_building_erp<20 {Crit_bilan_materiel_public1<-1;}
				else {Crit_bilan_materiel_public1<-0;}
			}
		}
}
}
if routes_inondees=0 {Crit_bilan_materiel_public2<-5;}
else {if routes_inondees<0.01 {Crit_bilan_materiel_public2<-4;}
	else {if routes_inondees<0.05 {Crit_bilan_materiel_public2<-3;}
		else {if routes_inondees<0.1 {Crit_bilan_materiel_public2<-2;}
			else {if routes_inondees<0.2 {Crit_bilan_materiel_public2<-1;}
				else {Crit_bilan_materiel_public1<-0;}
			}
		}
}
}
Crit_bilan_materiel_public<-round((Crit_bilan_materiel_public1*W_flooded_building_erp+Crit_bilan_materiel_public2*W_routes_inondees)/(W_flooded_building_erp+W_routes_inondees));

if flooded_building_prive=0 {Crit_bilan_materiel_prive1<-5;}
else {if flooded_building_prive<4 {Crit_bilan_materiel_prive1<-4;}
	else {if flooded_building_prive<10 {Crit_bilan_materiel_prive1<-3;}
		else {if flooded_building_prive<20 {Crit_bilan_materiel_prive1<-2;}
			else {if flooded_building_prive<50 {Crit_bilan_materiel_prive1<-1;}
				else {Crit_bilan_materiel_prive1<-0;}
			}
		}
}
}
if bien_endommage<0.1 {Crit_bilan_materiel_prive2<-5;}
else {if bien_endommage<0.2 {Crit_bilan_materiel_prive2<-4;}
	else {if bien_endommage<0.4 {Crit_bilan_materiel_prive2<-3;}
		else {if bien_endommage<0.6 {Crit_bilan_materiel_prive2<-2;}
			else {if bien_endommage<0.8 {Crit_bilan_materiel_prive2<-1;}
				else {Crit_bilan_materiel_prive2<-0;}
			}
		}
}
}
if flooded_car=0 {Crit_bilan_materiel_prive3<-5;}
else {if flooded_car<5 {Crit_bilan_materiel_prive3<-4;}
	else {if flooded_car<40 {Crit_bilan_materiel_prive3<-3;}
		else {if flooded_car<100 {Crit_bilan_materiel_prive3<-2;}
			else {if flooded_car<200 {Crit_bilan_materiel_prive3<-1;}
				else {Crit_bilan_materiel_prive3<-0;}
			}
		}
}
}
Crit_bilan_materiel_prive<-round((Crit_bilan_materiel_prive1*W_flooded_building_prive+Crit_bilan_materiel_prive2*W_bien_endommage+Crit_bilan_materiel_prive3*W_flooded_car)/(W_flooded_building_prive+W_bien_endommage+W_flooded_car));



if taux_artificilisation>0.15 {Crit_sols<-0;}
else {if taux_artificilisation>0.12 {Crit_sols<-1;}
	else {if taux_artificilisation>0.11 {Crit_sols<-2;}
		else {if taux_artificilisation>0.10 {Crit_sols<-3;}
			else {if taux_artificilisation>0.08{Crit_sols<-4;}
				else {Crit_sols<-5;}
			}
		}
}
}

if satisfaction<0.2 {Crit_satisfaction<-0;}
else {if satisfaction<0.4 {Crit_satisfaction<-1;}
	else {if satisfaction<0.55 {Crit_satisfaction<-2;}
		else {if satisfaction<0.65 {Crit_satisfaction<-3;}
			else {if satisfaction<0.75{Crit_satisfaction<-4;}
				else {Crit_satisfaction<-5;}
			}
		}
}
}


if empreinte_carbone>0.8 {Crit_environnement1<-0;}
else {if empreinte_carbone>0.6 {Crit_environnement1<-1;}
	else {if empreinte_carbone>0.45 {Crit_environnement1<-2;}
		else {if empreinte_carbone>0.35 {Crit_environnement1<-3;}
			else {if empreinte_carbone>0.2 {Crit_environnement1<-4;}
				else {Crit_environnement1<-5;}
			}
		}
}
}
if ratio_espace_vert<0.025 {Crit_environnement2<-0;}
else {if ratio_espace_vert<0.035 {Crit_environnement2<-1;}
	else {if ratio_espace_vert<0.037 {Crit_environnement2<-2;}
		else {if ratio_espace_vert<0.041 {Crit_environnement2<-3;}
			else {if ratio_espace_vert<0.045 {Crit_environnement2<-4;}
				else {Crit_environnement2<-5;}
			}
		}
}
}
if biodiversite<0.30 {Crit_environnement3<-0;}
else {if biodiversite<0.35 {Crit_environnement3<-1;}
	else {if biodiversite<0.40 {Crit_environnement3<-2;}
		else {if biodiversite<0.45 {Crit_environnement3<-3;}
			else {if biodiversite<0.5{Crit_environnement3<-4;}
				else {Crit_environnement3<-5;}
			}
		}
}
}
if taux_budget_env<0.05 {Crit_environnement4<-0;}
else {if taux_budget_env<0.010 {Crit_environnement4<-1;}
	else {if taux_budget_env<0.16 {Crit_environnement4<-2;}
		else {if taux_budget_env<0.23 {Crit_environnement4<-3;}
			else {if taux_budget_env<0.32 {Crit_environnement4<-4;}
				else {Crit_environnement4<-5;}
			}
		}
}
}
Crit_environnement<-round((Crit_environnement4*W_taux_budget_env+Crit_environnement3*W_biodiversite+Crit_environnement2*W_ratio_espace_vert+Crit_environnement1*W_empreinte_carbone)/(W_taux_budget_env+W_biodiversite+W_ratio_espace_vert+W_empreinte_carbone));

}




action reinitiate_indicators  {
ask road where (each.is_flooded) {is_flooded<-false;}
ask road where (each.usable=false) {usable<-true;}

ask building where (each.serious_flood) {serious_flood<-false;}
ask car where each.domaged {domaged<-false;}
ask people where each.injuried {injuried<-false;}
injuried_people<-0;
dead_people<-0;
}

//******************************** USER COMMAND ****************************************


	//current action type
	int action_type <- -1;	
	bool second_point<-false;
	point first_location;
	
	//images used for the buttons
	list<file> images <- [
		file("../images/bassin1.png"),
		file("../images/bassin2.png"),
		file("../images/bassin3.png"),
		file("../images/barrage 1.png"),
		file("../images/barrage 2.png"),
		file("../images/barrage 3.png"),
		file("../images/natura 1.png"),
		file("../images/natura 2.png"),
		file("../images/natura 3.png"),
		file("../images/noue 1.png"),
		file("../images/noue 2.png"),
		file("../images/noue 3.png")
		//file("../images/alarm.jpg")
	]; 
	
	action activate_act {
		bool  result;
		button selected_but <- first(button overlapping (circle(1) at_location #user_location));
		if(selected_but != nil) {
			ask selected_but {
				ask button {bord_col<-#black;}
				if (action_type != id) {
					action_type<-id;
					bord_col<-#red;
				} else {
					action_type<- -1;
					ask project  {		visible<-false;		}
				}
				
			}
			if action_type=0 {
				write "Bassin de retention ; site 1";
				ask project  {		visible<-false;		}
				ask project where (each.type=0 and each.Niveau_act=0) {
					visible<-true;
						result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Bassin de retention réalisé";
							do implement_project;
							result<-false;
						}
				}
			}
			if action_type=1 {
				write "Bassin de retention ; site 2";
				ask project  {		visible<-false;		}
				ask project where (each.type=0 and each.Niveau_act=1) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Bassin de retention réalisé";
							do implement_project;
							result<-false;
						}
				}
			}
			if action_type=2 {
				write "Bassin de retention ; site 3";
				ask project  {		visible<-false;		}
				ask project where (each.type=0 and each.Niveau_act=2) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Bassin de retention réalisé";
							do implement_project;
							result<-false;
						}
				}
			}
			
			if action_type=3 {
				write "Barrage ; niveau 1";
				ask project  {		visible<-false;		}
				ask project where (each.type=1 and each.Niveau_act=0) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Barrage réalisé";
							do implement_project;
							result<-false;
					create obstacle {
					shape<-self.shape;
					location<-self.location;
					height<-2#m;
				ask cell overlapping self {
					is_dyke<-true;
					dyke_height<-myself.height;
			}
				}
						}
				}
			}
			
				if action_type=4 {
				write "Barrage ; niveau 2";
				ask project  {		visible<-false;		}
				ask project where (each.type=1 and each.Niveau_act=1) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Barrage réalisé";
							do implement_project;
							result<-false;
					create obstacle {
					shape<-self.shape;
					location<-self.location;
					height<-3#m;
				ask cell overlapping self {
					is_dyke<-true;
					
					dyke_height<-myself.height;
			}
				}
						}
				}
			}
			
			if action_type=5 {
				write "Barrage ; niveau 3";
				ask project  {		visible<-false;		}
				ask project where (each.type=1 and each.Niveau_act=2) {
		
				
					
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Barrage réalisé";
							do implement_project;
							result<-false;
							visible<-true;
					create obstacle {
					shape<-self.shape;
					location<-self.location;
					height<-5#m;
				ask cell overlapping self {
					is_dyke<-true;
					
					dyke_height<-myself.height;
			}
				}
						}
				}
			}
			
				if action_type=6 {
				write "Extension de la zone natura 2000 ; niveau 1";
				ask project  {		visible<-false;		}
				ask project where (each.type=2 and each.Niveau_act=0) {
	
					visible<-true;
						result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Extension réalisée";
							do implement_project;
							result<-false;
					create natura {
					shape<-self.shape;
					location<-self.location;
				}
						}
				}
			}
			
			
				if action_type=7 {
				write "Extension de la zone natura 2000 ; niveau 2";
				ask project  {		visible<-false;		}
				ask project where (each.type=2 and each.Niveau_act=1) {
				
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Extension réalisée";
							do implement_project;
							result<-false;
										create natura {
					shape<-self.shape;
					location<-self.location;
				}
						}
				}
			}
			
			
				if action_type=8 {
				write "Extension de la zone natura 2000 ; niveau 3";
				ask project  {		visible<-false;		}
				ask project where (each.type=2 and each.Niveau_act=2) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Extension réalisée";
							do implement_project;
							result<-false;
										create natura {
					shape<-self.shape;
					location<-self.location;
				}
						}
				}
			}
			
				
				if action_type=9 {
				write "Réalisation de noues ; niveau 1";
				ask project  {		visible<-false;		}
				ask project where (each.type=3 and each.Niveau_act=0) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Noue réalisée";
							do implement_project;
							result<-false;
						}
				}
			}
			
			
				if action_type=10 {
				write "Réalisation de noues ; niveau 2";
				ask project  {		visible<-false;		}
				ask project where (each.type=3 and each.Niveau_act=1) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Noue réalisée";
							do implement_project;
							result<-false;
						}
				}
			}
			
			
				if action_type=11 {
				write "Réalisation de noues ; niveau 3";
				ask project  {		visible<-false;		}
				ask project where (each.type=3 and each.Niveau_act=2) {
					visible<-true;
							result <- user_confirm("Confirmation dialog box","Voulez vous vraiment réaliser ce projet?");
						if result{write "Noue réalisée";
							do implement_project;
							result<-false;
						}
				}
			}
		}
	}

/* 	action cell_management {
		cell selected_cell <- first(cell overlapping (circle(1.0) at_location #user_location));
		building selected_building<- first(building overlapping (circle(1.0) at_location #user_location));
		if action_type=0 {	//dyke
					do create_obstacle;		
				//	write ("new dyke : " +name);
				}
		if(selected_cell != nil) {
			ask selected_cell {
				if action_type=1 {	//building construction
					write ("construction complete");
					create building {
						shape<-square (15#m);
						location<-myself.location;
						category<-0;
					}
					
					
				}
				if action_type=3 {	
					write ("Under construction");
				}
				
		
			}
		}
			if(selected_building != nil) {
			ask selected_building {
				if action_type=2 {	//demolish		
					write ("demolition complete");
					do die;	
				}
				
				}
	}
	
}*/


action create_obstacle {
		
		if action_type=0 and second_point{	//dyke
					geometry line_dyke<-line(first_location,#user_location);	
					create obstacle {shape<-line_dyke;	
					ask cell overlapping self {
						is_dyke<-true;
						dyke_height<-myself.height;
							}
					}	
						write ("digue créée ");
				}
				
			if action_type=0 and !second_point{	//dyke
					first_location<-#user_location;	
					write ("choose another point ");
				}
				
			if 	second_point{second_point<-false;}
			else {second_point<-true;}
}



user_command "visualisation plu/relief" action:vizu_chnge;
user_command "mode gestion/mode inondation" action:mode_chnge;
	
	action vizu_chnge {
		if plu_mod {
			plu_mod<-false;
			ask cell {do update_color;}
		}
		else {
			plu_mod<-true;
			ask cell {do see_plu;}
		}
	}
	
	
	
		action mode_chnge {
		if mode_flood {
			mode_flood<-false;
			write "mode gestion";
		}
		else {
			step <-  time_step; 
			
			mode_flood<-true;
			write "mode inondation";
		}
	}
	

}
//***************************  END of GLOBAL **********************************************************************

//***********************************************************************************************************
//***************************  SEA    **********************************************************************
//***********************************************************************************************************
species sea {
	rgb color <- #blue;


	aspect default {
		draw shape color: color;
	}

}


//***********************************************************************************************************
//***************************  SPEC RIVER    **********************************************************************
//***********************************************************************************************************
species spe_riv {
int category;
aspect default {
		draw shape color:#red;
	}
}




//***********************************************************************************************************
//***************************  GREEN AREA   **********************************************************************
//***********************************************************************************************************
species green_area {
	rgb color <- rgb(0,128,0,0.35);
	list<cell> my_cells;

	aspect default {
		draw shape color: color;
		
	}

}


//***********************************************************************************************************
//***************************  NATURA2000   **********************************************************************
//***********************************************************************************************************
species natura {
	rgb color <- rgb(0,50,0,0.3);
	list<cell> my_cells;

	aspect default {
		draw shape color: color;
		
	}

}


//***********************************************************************************************************
//***************************  PARKING   **********************************************************************
//***********************************************************************************************************
species parking {
	rgb color <- #grey;
	list<cell> my_cells;
	bool is_full<-false;
	int capacity<-round(shape.area/15#m2);
	int nb_cars;
	list<car> my_cars;
	
	
	aspect default {
		draw shape color: color;
		
	}

}


//***********************************************************************************************************
//***************************  PROJECT    **********************************************************************
//***********************************************************************************************************
species project {
int Niveau_act;
int type; // 0 : bassin de retention
bool visible<-false;
bool implemented<-false;
list<cell> my_cells;
list<cell> my_neigh_cells;

float volume;
float depth;
float water_into<-0.0;
float distance_application<-200#m;


action implement_project {
	implemented<-true;
	visible<-true;
	ask building overlapping self {
		ask people where (each.my_building=self) {
			my_building<-one_of((building where (each.category=0)));
		}
	do die;	
	}
	list<road> supp_roads<-road overlapping(self);
	list<road> possible_roads<-road - supp_roads;
	ask car  overlapping self {
	location<-(possible_roads closest_to(myself)).location;
	}
	
	ask people overlapping self {
	location<-(building closest_to(myself)).location;
	satisfaction<-rnd(5)/10;
	}
	
	ask parking  overlapping self {
	do die;	
	}

	ask green_area  overlapping self {
	do die;	
	}
	
	ask pluvial_network  overlapping self {
	do die;	
	}
	
	ask supp_roads {
	do die;	
	}
	
	ask world {do update_road_work;	}
	my_cells<-cell overlapping self;
	
	my_neigh_cells<-cell where ((each distance_to self)<distance_application); 
	
	//safe_roads <-road where ((each distance_to rivers) > 100#m );
	
	/*ask my_cells{
		altitude<- (myself.my_cells min_of(each.altitude));
		loop ne over:neighbors {
			add ne to:myself.my_neigh_cells;	
		}
	}
	my_neigh_cells<-cells 
	
	remove_duplicates(my_neigh_cells);
	
	*/
}




action making {
	if implemented {
	if type=0 {
		do collect_water;		
	}
	}
}


action collect_water {
		if (water_into<volume) {
		ask my_neigh_cells {
		if (myself.water_into+water_volume<myself.volume) {
		myself.water_into<-myself.water_into+water_volume;
		water_volume<-0.0;
		do compute_water_altitude;
		}
	}
	}
	
}


	aspect default {
	if visible or implemented{
		draw shape color:#gamared border:#black ;		
		}
	}
	
}






//***********************************************************************************************************
//***************************  ROAD    **********************************************************************
//***********************************************************************************************************
species road {
	rgb color<-#grey;
	int category; //0:city, 1:national, 2;highway
	string type;
	int val_water;
	float cell_water_max;
	list<cell> my_cells;
	bool usable <- true;
	float speed_coeff <- 1.0 min: 0.01;
	bool is_flooded;

	action update_flood {
		cell_water_max <- max(my_cells collect each.water_height);
		speed_coeff <- 1.0 / (1 + cell_water_max) ;
		usable <- true;
		if cell_water_max > 20 #cm {
			usable <- false;
			not_usable_roads << self;
		}
		
/* 		if cell_water_max > 5 #cm {
		color <- rgb([255, val_water, 0]);
	}*/

	}

	aspect default {
		draw shape color: color;
	}

}

//***********************************************************************************************************
//***************************  RIVER    **********************************************************************
//***********************************************************************************************************
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


//***********************************************************************************************************
//***************************  PLUVIAL NETWORK    **********************************************************************
//***********************************************************************************************************
species pluvial_network {
	rgb color <- #darkblue;
	string type;
	list<cell> my_cells;
	float water_height <- 0 #m;
	float altitude;
	point my_location;
	float area_capacity<-1#m2;

	aspect default {
		draw shape color: color;
	}

}


//***********************************************************************************************************
//***************************  BUILDING **********************************************************************
//***********************************************************************************************************
species building {
	string type;
	int category; //0: residentiel, 1: commerce, 2:erp
	float prix_moyen<-2000.0;
	list<cell> my_cells;
	list<cell> my_neighbour_cells;
	float altitude;
	float impermeability_init <- (0.3+rnd(0.5)) ; //1: impermeable, 0:permeable
	float max_impermeability <- impermeability_init + max_impermeability_building_increase max: 1.0;
	float impermeability <- impermeability_init max: max_impermeability; 
	float water_height <- 0.0;
	float water_evacuation <- 0.5 #m3 / #mn;
	point my_location;
	float bd_height <- rnd(3,10) #m ;
	float state <- 1.0; //entre 0 et 1
	float init_vulnerability <- rnd(1.0);
	float min_vulnerability <- init_vulnerability - max_vulnerability_building_decrease min: 0.0;
	float vulnerability  <- init_vulnerability min: min_vulnerability; //between 0.1 et 1 (very vulnerable) 
	bool is_water;
	rgb my_color <- #grey;
	bool nrj_on <- true;
	int nb_stairs min: 0 <- round(bd_height / 3.0) - 1;
	bool serious_flood<-false; 
	float water_level_flooded<-30#cm;
	
	bool neighbour_water <- false ;
	bool water_cell <- false;
	
	action update_water {
		float cell_water_max;
		cell_water_max <- max(my_cells collect each.water_height);

		
		if water_height<cell_water_max {
			water_height <-water_height + (cell_water_max-water_height)* (1 - impermeability);
		}
		else {
			water_height <- max([0,water_height - (water_evacuation / shape.area * step/1#mn)]);
		}
		
		state <- min([state,max([0, state - (water_height / 10#m / (step / (1 #mn))) * vulnerability])]);
		if water_height>water_level_flooded {
			serious_flood<-true;
		}
		if not water_cell {
			water_cell <- cell_water_max > water_height_perception;
		
		}
		if not neighbour_water {
			neighbour_water <- (my_neighbour_cells first_with (each.water_height > water_height_perception)) != nil;
		
		}
		
	}
	action update_water_color {
		if (display_water) {
			int val_water <- 0;
			val_water <- max([0, min([255, int(255 * (1 - (water_height / 1.0#m)))])]);
			if water_height>5#cm {
			my_color <- rgb([255, val_water, val_water]);}
		}
	}

	aspect default {
		draw shape color: my_color depth: bd_height border:#black;
	}

}

//***********************************************************************************************************
//***************************  CAR **********************************************************************
//***********************************************************************************************************
species car {
	people my_owner;
	cell my_cell;
	point my_location;
	rgb my_color <- #green;
	bool domaged<-false;
	float problem_water_height<-(10+rnd(20))#cm;
	bool usable<-true;
	bool is_parked<-false;
	
	init {
		do define_cell;
	}
		
	action define_cell {
		my_cell<-cell(location);
		if my_cell=nil {my_cell<-cell closest_to(self);}
		
	}
	action update_state {
		if my_cell.water_height>problem_water_height {domaged<-true;}
		my_color <- #green;
		if domaged {my_color <- #red;}
		
		
		
	}
	aspect default {
		draw rectangle(3 #m, 2#m) depth:1.5#m color: my_color ;
	}
	
	

}

//***********************************************************************************************************
//***************************  INSTITUTION **********************************************************************
//***********************************************************************************************************
species institution {
	float flood_informed_people <- 0.01;
	float DICRIM_information <- 0.1;
	bool canal_maintenance<-true;
	bool river_maintenance<-false;
	
}


//***********************************************************************************************************
//***************************  PLU **********************************************************************
//***********************************************************************************************************
species PLU {
	int category; 	// 0: urbain, 1: a urbaniser, 2:agricole, 3:nat, 4:mer 
	
}


//***********************************************************************************************************
//***************************  PEOPLE   **********************************************************************
//***********************************************************************************************************
species people skills: [moving]  {
	building my_building;
	building my_destination_building;
	car my_car;
	bool have_car;
	
	int current_stair;
	
	point my_location;
	bool in_car <- false;
	bool inside<-true;
	bool injuried<-false;
	bool starting_at_home;
	bool car_vulnerable<-flip(0.3);
	
	
	bool know_flood_is_coming<-flip(0.8);
	bool know_rules<-flip(0.3);
		
	float satisfaction<-0.5; //0: not satisfy at all, 1: very satisfied
	float obedience<-0.8;
	float proba_agenda<-0.05;  // quand il pleut, pas trop envie d'aller se promener
	float informed_on_flood<-0.8;
	float informed_on_rules<-0.3;
	
	float flooded_road_percep_distance<-1000#m;
	
	float water_height_danger_car <- (10 + rnd(30)) #cm;
	float water_height_danger_pied <- (10 + rnd(90)) #cm;
	
	float my_speed {
		if in_car {
			if my_car.usable {return 30 #km / #h;}
			if !my_car.usable {return 2 #km / #h;}
		} else {
			return 2 #km / #h;
		}

	}

	float fear_level <- 0.0 ;
	float danger_inside <- 0.0; //between 0 and 1 (1 danger of imeediate death)
	float danger_outside <- 0.0; //between 0 and 1 (1 danger of imeediate death)
	float proba_evacuation<-0.0;
	float save_car<-0.3;
	point current_target;
	point final_target;

	rgb my_color <- #mediumvioletred;
	
	bool return_home <- false;
	bool doing_agenda<-false;
	bool doing_evacuate <- false;
	bool doing_protect_car<-false;
	bool doing_rules<-false;
	
	list<int> known_blocked_roads;
	
	graph current_graph;
	float outside_test_period <- rnd(15,30) #mn;
	cell my_current_cell;
	
	float water_level <- 0.0;
	float prev_water_inside <- 0.0;
	float prev_water_outside <- 0.0;
	float max_danger_inside<-0.0;
	float max_danger_outside<-0.0;
	
	
	

	reflex acting when:mode_flood {
		if (time mod 10#mn) = 0 {do test_proba;} //when: (time mod 10#mn) = 0
		do my_perception;
		if (time mod 10#mn) = 0 {if flip(proba_agenda) {doing_agenda<-true;}
		if know_flood_is_coming and have_car and fear_level<0.2 and flip(save_car) and car_vulnerable{
			doing_protect_car<-true;
			doing_agenda<-false;
			doing_evacuate<-false;
			doing_rules<-false;
		}
		if know_rules and know_flood_is_coming {
			if flip(obedience) 
			{	doing_rules<-true;
				doing_agenda<-false;
				doing_evacuate<-false;
				doing_protect_car<-false;
				proba_agenda<-proba_agenda/3;
			} 
		}
		else {if flip(informed_on_flood/10)
			{
				doing_rules<-true;
				doing_agenda<-false;
				doing_evacuate<-false;
				doing_protect_car<-false;	
		}
		}
		}
		
		do update_danger;
		
		if (doing_agenda) {do agenda;}
		if (doing_evacuate) {do evacuate;}
		if doing_protect_car {do protect_my_car;}
		if (doing_rules) {do follow_rules;}
		
	}
	
	
	
	//***************************  perception ********************************
	action my_perception {
		if mode_flood {
		bool water_cell_neighbour <- false;
		bool water_cell <- false;
		bool water_building <- false;
		fear_level<-0.0;
		danger_inside<-0.0;
		danger_outside<-0.0;
		
		if know_flood_is_coming{
			fear_level<-fear_level+0.005;
		}
		
		
		if inside {
			float whp <- water_height_perception;
			water_cell <- my_building.water_cell;
			water_cell_neighbour <- my_building.neighbour_water;
			water_level <- my_building.water_height;
			prev_water_inside <- my_building.water_height ;
			
			if my_building.water_height >= water_height_problem {
				fear_level<-fear_level+0.01;	
			}
			
			if my_building.water_height >= water_height_problem {
				water_building <- true;
				if current_stair<my_building.nb_stairs {current_stair<-my_building.nb_stairs;}
				if my_building.nb_stairs=0 {fear_level<-fear_level+0.2;}
				else {fear_level<-fear_level+0.05;}
							
			}
		} else if (my_current_cell != nil) {
			water_level <- my_current_cell.water_height;
			prev_water_outside <- my_current_cell.water_height;
			} 
		}
		
	}
	
	
	action update_danger {
		if inside {
			if (my_building.water_height >(3*(current_stair+1))) {
					if (my_building.nrj_on) {
						danger_inside <- min([danger_inside,min([1.0, (my_building.water_height - water_height_danger_inside_energy_on)])]); //entre 0 et 1 (1 danger de mort imminente) 
					}else {
						danger_inside <- min([danger_inside,min([1.0, (my_building.water_height - water_height_danger_inside_energy_off)])]); //entre 0 et 1 (1 danger de mort imminente) 
					}
					if danger_inside >0 {
						max_danger_inside <- max(max_danger_inside, danger_inside);
					}
				}		
		}
		else if my_current_cell != nil{
			float wh<-my_current_cell.water_height; 
			if in_car {danger_outside<-max([danger_outside,max([0,min([1.0, (wh-water_height_danger_car)/water_height_danger_car])])]);	}
			else {danger_outside<-max([danger_outside,max([0,min([1.0, (wh-water_height_danger_pied)/water_height_danger_pied])])]);}
			if danger_outside >0 {
				max_danger_outside <- max(max_danger_outside, danger_outside);		
				if injuried=false {
					injuried<-true;
					injuried_people <- injuried_people+1;
				}			
			}
		}
		if injuried {fear_level<-fear_level+0.2;}
		if flip (fear_level) {
			if flip(0.2) {
				doing_evacuate<-true;
				doing_agenda<-false;
				doing_protect_car<-false;
			}
		}
	}
	
	action test_proba  {
		if flip(max_danger_outside) or flip(max_danger_inside) {
				if flip(max_danger_outside/10) or flip(max_danger_inside/10) {
					do to_die;
				} else {
					if injuried=false {
							injuried<-true;
							injuried_people <- injuried_people+1;
						}
			}
			
		}
		max_danger_inside <- 0.0;
		max_danger_outside <- 0.0;
	}
	
		
	action to_die {
			dead_people <- dead_people + 1;
			if (injuried) {
				injuried_people <- injuried_people - 1;
			}
		do die;
	}
		
	action agenda{
			current_stair<-0;
			inside<-false;
			if (final_target = nil) {
				if location=my_building.location {my_destination_building<- (one_of(building where (each.category>0)));}
				else {my_destination_building<-my_building;}
				final_target <-my_destination_building.location;
				}
			
			if (have_car) {	current_target <- my_car.location;	} 
			else {	current_target <- final_target;	}


			if (current_target = location) {
				if (current_target = final_target) {	
					if (in_car) {
						ask my_car {location<-(road closest_to(self)).location;}
						in_car<-false;
					}
					doing_agenda<-false;
					inside<-true;
				} else {
					in_car <- true;
					current_target <- final_target;
					road_network_simple<-as_edge_graph(road where each.usable);
					current_graph <-road_network_simple;
				}
			
		}
		do moving;
		if(in_car) {my_car.location <- location;	}
		inside<-false;
	}
	
		action evacuate  {
		current_stair<-0;
		inside<-false;
		speed <- my_speed();
		if (final_target = nil) {
			final_target <- (escape_cells with_min_of (each.location distance_to location)).location;
			if (have_car) {
				current_target <- my_car.location;
			} else {
				current_target <- final_target;
			}

		} else {
			do moving;
			if( in_car) {
				my_car.location <- location;
			}
			if (current_target = location) {
				if (current_target = final_target) {
					if (in_car) {ask my_car {do die;}}
					do die;
				} else {
					in_car <- true;
					current_target <- final_target;
				}
			}
		}
	}

	action moving {
		inside<-false;
	 /*list<road> rd <- not_usable_roads where ((each distance_to self) < flooded_road_percep_distance) ;
		if not empty(rd) {
			loop r over: rd {
				int id <- int(r);
				if not(id in known_blocked_roads) {
					known_blocked_roads << id;
					known_blocked_roads <- known_blocked_roads sort_by each ;
					current_path <- nil;
					current_edge <- nil;
					if not (known_blocked_roads in road_network_custom.keys) {
						graph a_graph <- (as_edge_graph(road - known_blocked_roads) use_cache false) with_shortest_path_algorithm #NBAStar;
						road_network_custom[known_blocked_roads] <- a_graph;
						current_graph <- a_graph;
					} 
				}
			}	
		
		}*/	
		if (current_graph = nil) {
		//	current_graph <- road_network_custom[known_blocked_roads];
			current_graph <-road_network_simple;
		}
	//	do goto target: current_target on: current_graph = nil ? first(road_network_custom.values) :  current_graph move_weights: current_weights ;
		do goto target: current_target on: current_graph  move_weights: current_weights ;
		
		if (location = current_target) {current_graph <- nil;	}			
	}
	

	action follow_rules {
		if location=my_building.location {
		inside<-true;
		if my_building.nrj_on {do turn_off_nrj;}
		else {
			if my_building.nb_stairs>0 and fear_level>0.2 {current_stair <- my_building.nb_stairs;}
			else if fear_level>0.1{do protect_properties;}
			else {do weather_strip_house;}
		}
		if flip(0.2) {do give_information;}
	}
	if !inside  {
		final_target<-my_building.location;
		if (have_car) {	current_target <- my_car.location;	} 
			else {current_target <- final_target;	}
			if (current_target = location) {
				if (current_target = final_target) {	
					if (in_car) {
						ask my_car {location<-(road closest_to(self)).location;}
						in_car<-false;
					}
				} else {
					in_car <- true;
					current_target <- final_target;
					current_graph <-road_network_simple;
				}
		}
		do moving;
		if(in_car) {my_car.location <- location;	}
		
		
		
	}
	
	
	
	}

	action protect_properties {
		current_stair<-0;
		my_building.vulnerability <- my_building.vulnerability - (0.2 * step / 1 #h);
	}


	action turn_off_nrj  {
		current_stair<-0;
		my_building.nrj_on <- false;
	}


	action weather_strip_house {
		current_stair<-0;
		my_building.impermeability <- my_building.impermeability + (0.05*step / 1 #h);
	}
	



	action give_information {
		ask one_of(people) {
			know_rules<-true; 
			know_flood_is_coming<-true;
		}
	}



	action protect_my_car {
		inside<-false;
		current_stair <- 0;	
		speed <- my_speed();
		if (final_target = nil) {
			//road a_road <- safe_roads[rnd_choice(safe_roads collect (1.0/(1 + each.location distance_to my_car.location)))];
			road a_road <- one_of(safe_roads);
			final_target <- any_location_in(a_road);
			current_target <- my_car.location;
		} else {
			do moving;
			if( in_car) {
				my_car.location <- location;
			}
			if (current_target = location) {
				if (current_target = final_target) {
					in_car <- false;
					current_target <- any_location_in(my_building);
					return_home <- true;
				} else {
					if (return_home) {
						return_home <- false;
					} else {
						in_car <- true;
						current_target <- final_target;
					}
					
				}
				

			}

		}
	}


	action protect_my_properties {
		do protect_properties;
		
		}


	action turn_off_nrj {
		current_stair<-0;
		my_building.nrj_on <- false;
	}

	action weather_strip_house  {
		do weather_strip_house;
	}
	
	
	action weather_strip_house {
		current_stair<-0;
		my_building.impermeability <- my_building.impermeability + (0.05*step / 1 #h);
		if (my_building.impermeability >= my_building.max_impermeability) {
		}
}




	//***************************  APPARENCE  ********************************************************
	aspect default {
		float haut;
		if inside{haut<-10#m;} 
		else {haut<-3#m;}
		draw cylinder(1 #m, haut) color: my_color;
	}

}



//***********************************************************************************************************
//*************************** OBSTACLE **********************************************************************
//***********************************************************************************************************
species obstacle {
	float height <- 2#m;
	int resistance<-2;
	rgb color<-#violet;
	bool is_destroyed<-false;

		aspect default {
		draw shape+(0.5,10,#flat)  depth:height color: color at:location+{0,0,height};
	}
	
}


//***********************************************************************************************************
//***************************  CELL     **********************************************************************
//***********************************************************************************************************
grid cell neighbors: 8 file: mnt_file {
	bool is_active <- false;
	float water_height;
	float water_river_height;
	float water_volume;
	float altitude <- grid_value;
	bool is_river <- false;
	bool is_river_full<-false;
	bool is_sea <- false;
	bool is_dyke<-false;
	bool is_natura<-false;
	bool is_pluvial_network<-false;
	bool is_parking<-false;
	float water_evacuation_pl_net<-0.0;
	float permeability<-0.0;
	bool already;
	float water_cell_altitude;
	float river_altitude;
	float water_altitude;
	float remaining_time;
	
	list<building> my_buildings;
	list<river> my_rivers;
	list<green_area> my_green_areas;
	float river_broad<-0.0;
	float river_depth<-0.0;
	bool escape_cell;
	rgb color_plu;
	int plu_typ<-0; // 0: urbain, 1: a urbaniser, 2:agricole, 3:nat, 4:mer 
	
	//dyke
	float dyke_height<-0.0;
	float water_pressure ;  //from 0 (no pressure) to 1 (max pressure)
	float breaking_probability<-0.01; //we assume that this is the probability of breaking with max pressure for each min
	
	bool is_critical<-false;
	
	float K<-25.0; //coefficient de Strickler
	float slope;
	float water_abs<-0.0;
	float water_abs_max<-0.01;
	map<cell, float> delta_alt_neigh;
	map<cell, float> slope_neigh;
	list<cell> flow_cells;

	float prop;
	float volume_max;
	float volume_distrib;
	float volume_distrib_cell;
	bool is_flowed<-false;
	bool may_flow_cell;
	float prop_flow;



	
	action see_plu {
	if plu_typ=0 {color_plu<-#darkgrey;}
	if plu_typ=1 {color_plu<-#grey;}
	if plu_typ=2 {color_plu<-#yellow;}
	if plu_typ=3 {color_plu<-#green;}
	if plu_typ=4  {color_plu<-#blue;}
	}
	// 0: urbain, 1: a urbaniser, 2:agricole, 3:nat, 4:mer 
	
	
	//Reflex to break the dynamic of the water
	action breaking_dyke{
		water_pressure<- min([1.0, water_height / dyke_height]);		
		float timing <-step/1 #mn;
				loop while:timing>=0 {
					if flip(breaking_probability*water_pressure) {
						is_dyke<-false;
						dyke_height<-0#m;
						//ask obstacle overlaping myself {} à faire
					}
					timing<-timing-1;
		}
	}
	
	
	action compute_permeability {
	if plu_typ=0 {
		permeability<-0.01;
		water_abs_max<-shape.area*3#cm;
	}
	if plu_typ=1 {
		permeability<-0.45;
		water_abs_max<-shape.area*20#cm;
	}
	if plu_typ=2 {
		permeability<-0.55;
		water_abs_max<-shape.area*40#cm;
	}
	if plu_typ=3 {
		permeability<-0.90;
		water_abs_max<-shape.area*60#cm;
	}
	}
	
	action absorb_water {
	water_volume<-water_volume*(1-permeability);
	water_abs<-water_abs+water_volume;
	if water_abs>water_abs_max {permeability<-0.0;}
	else {permeability<-max([0,permeability-(water_abs_max-water_volume)/water_abs_max]);}
	}
	
	
	
	
	
	action compute_water_altitude {
			is_river_full<-true;
			float water_volume_no_river<-water_volume;
			water_river_height<-0.0;
			if is_river { 
			float vol_river<-max([river_depth*sqrt(cell_area)*river_depth]);
			float prop_river<-water_volume/vol_river;
			water_river_height<-river_depth;
			if prop_river<1 {
				is_river_full<-false;
				vol_river<-water_volume;
				water_river_height<-river_depth*prop_river;
			}
			water_volume_no_river<-water_volume-vol_river;
			}
			
	//		if is_river {water_river_height<-min([water_volume/(sqrt(cell_area)*river_broad),river_depth]);}
	//		else {water_river_height<-0.0;}
			water_height<-max([0,water_volume_no_river/cell_area]);
			water_altitude<-altitude -river_depth+water_river_height+ water_height;
			if water_height>1#m {is_critical<-true;}
	}
		
		


	//Action to flow the water 
	action flow2 {
		is_flowed<-false;
		if (water_volume>10) {	
			int nb_neighbors<-length(neighbors);   
			list<cell> neighbour_cells_al <- neighbors where (each.already);
			list<cell> cell_to_flow;		
	//		V<-3#m/#s;
	//		dp<-V*step; //distance parcourue en 1 step
			//prop<-min([1,max([0.1,(dp-sqrt(cell_area))/sqrt(cell_area)])]); //proportion eau transmise
			prop<-1.0;
		//	volume_distrib<-max([0,water_volume*prop]);
			volume_distrib<-water_volume*prop;
			
			
			float w_a<-water_altitude;
		//	add self to:cell_to_flow;
			ask neighbour_cells_al {
			//	do absorb_water;	
				if (is_river_full and w_a > water_altitude and (w_a > (altitude+obstacle_height-river_depth))) or (!is_river_full and w_a > water_altitude and (w_a > (altitude-river_depth))) {
					add self to:cell_to_flow;
					ask neighbors where (each.already) {
						if (is_river_full and w_a > water_altitude and (w_a > (altitude+obstacle_height-river_depth))) or (!is_river_full and w_a > water_altitude and (w_a > (altitude-river_depth))) {
						//	add myself to:cell_to_flow;
							ask neighbors where (each.already) {
								if (is_river_full and w_a > water_altitude and (w_a > (altitude+obstacle_height-river_depth))) or (!is_river_full and w_a > water_altitude and (w_a > (altitude-river_depth))) {
								//	add myself to:cell_to_flow;					
								}
								}
							}
							}
						}
			}

					flow_cells <- remove_duplicates(cell_to_flow);	
					float tot_den<-flow_cells sum_of (max([0,w_a-(each.altitude-each.river_depth)]));
		//			write name;
		//			write tot_den;
		//			write flow_cells;
		//			write "************************";
					
				//	remove self from:(cell_to_flow);					
					if (!empty(flow_cells) and tot_den>0) {			
						is_flowed<-true;
			
						//prop_flow<-1/length(flow_cells);
						//float slope_sum<-flow_cells sum_of(slope_neigh[each]);
						ask flow_cells {
							prop_flow<-(w_a-(altitude-river_depth))/tot_den;
							volume_distrib_cell<-with_precision(myself.volume_distrib*prop_flow,4);
							water_volume <- water_volume + volume_distrib_cell;	
							do compute_water_altitude;
							
						} 
				 		water_volume <- water_volume - volume_distrib;
				 		
				 //		write "water distrib : "+(volume_distrib);
				 //		write "vol distrib cell : "+flow_cells sum_of(each.volume_distrib_cell);
				 //		write "wv-vd : "+(volume_distrib);
				 //		write "vol distrib cell : "+flow_cells sum_of(each.volume_distrib_cell);
				 //		write "volume_distrib : "+volume_distrib;
				 //		write "vol distrib cell : "+flow_cells sum_of(each.prop_flow);
				 //		write "tot_den : "+tot_den;
						do compute_water_altitude;
					
			} 
 	}
		already <- true;
		if is_sea {	water_height <- 0.0;}
}






	//Update the color of the cell
	action update_color {
		if (!is_sea) {color<-rgb(int(min([255,max([245 - 0.8 *altitude, 0])])), int(min([255,max([245 - 1.2 *altitude, 0])])), int(min([255,max([0,220 - 2 * altitude])])));}
	
		int val_water <- 0;

		
			/* 	if is_canal {
			color <- #mediumseagreen;
		}*/
			
	//	if (water_height>1#cm or water_river_height>1#cm) {
		if ( water_river_height>1#cm) {
			color <- #green;
		}
		
		if (water_height>5#cm) {
		val_water <- max([0, min([200, int(200 * (1 - (water_height /2#m)))])]);
		color <- rgb([val_water, val_water, 255]);
		}
		if is_critical {color<-#red;}
		if (is_sea) {color<-#blue;}
	}

	aspect map {
	
//		if is_dyke{	draw rectangle(sqrt(cell_area)#m,3#m) depth:dyke_height rotate:45 color:#darkcyan;	}
	//	if !plu_mod {draw shape  depth:altitude+water_height color: color border: #black;	}
		if !plu_mod {draw shape   color: color ;	}
		else {draw shape  color: color_plu;	}
		
		
		//draw square(sqrt(cell_area)) color:color depth:water_altitude ;

	}

	aspect map3D {		
		draw square(sqrt(cell_area)) color:color depth:altitude ;

	}

}

/********************************************************************** */
//***********************************************************************************************************
//***************************  BOUTONS  **********************************************************************
//***********************************************************************************************************




grid button width:3 height:4 
{
	int id <- int(self);
	rgb bord_col<-#black;
	aspect normal {
		draw rectangle(shape.width * 0.8,shape.height * 0.8).contour + (shape.height * 0.01) color: bord_col;
		draw image_file(images[id]) size:{shape.width,shape.height} ;
	}
}

//***********************************************************************************************************
//***************************  OUTPUT  **********************************************************************
//***********************************************************************************************************



experiment "Simulation" type: gui {
	
	output {
		display map type: opengl background: #black draw_env: false {
			grid cell  triangulation:false refresh: true ;
			species cell  refresh: true aspect:map;
			species green_area;
			//species natura;	
			species building;
			species road;
			species parking;
			species obstacle;
			species river;
	//		species pluvial_network;
			species people;
			species car;
			//species project;	
			
			
			overlay position: { 5, 5 } size: { 250 #px, 80 #px } background: # black transparency: 0.5 border: #black rounded: true
            {
          
                
                    draw date_in at: { 40#px, 20#px + 4#px } color: # white font: font("Helvetica", 18, #bold);
                     draw nb_blesse at: { 40#px, 40#px + 4#px } color: # white font: font("Helvetica", 18, #bold);
                      draw nb_mort at: { 40#px, 60#px + 4#px } color: # white font: font("Helvetica", 18, #bold);

            }
			
			
			}
			
				display map3D type: opengl background: #black draw_env: false {
			grid cell  triangulation:false refresh: true ;
			species cell  refresh: true aspect:map3D;				
		}
		
		
		display "Indicateurs"
		{
			//Attractivité
			graphics "radars axis" 
			size: {0.4,0.4}  position: {0, 0}
			refresh: false{
					loop i from: 0 to:2 {
					geometry a <- axis3[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * 1.1;
					draw axis_labelAtt[i]  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
			graphics "radars surface" 
			size: {0.4,0.4} position: {0, 0}
			transparency: 0.5 {
				list<int> values <- [Crit_logement, Crit_infrastructure, Crit_economie];
				list<point> points <- world.define_surface3(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: 2 {
					float angle <- (first(axis3[i].points) towards last(axis3[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i])  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
		
			//Développement durable
			graphics "radars axis" 
			size: {0.4,0.4} position: {0.4, 0.5}
			refresh: false{
					loop i from: 0 to: 2 {
					geometry a <- axis3[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * 1.1;
					draw axis_labelDD[i]  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
			graphics "radars surface" 
			size: {0.4,0.4} position: {0.4, 0.5}
			transparency: 0.5 {
				list<int> values <- [Crit_sols, Crit_satisfaction, Crit_environnement];
				list<point> points <- world.define_surface3(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: 2 {
					float angle <- (first(axis3[i].points) towards last(axis3[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i])  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
		
			//Sécurité
			graphics "radars axis" 
			size: {0.4,0.4} position: {0, 0.5}
			refresh: false{
					loop i from: 0 to: 2 {
					geometry a <- axis3[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * 1.1;
					draw axis_labelSec[i]  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
			graphics "radars surface" 
			size: {0.4,0.4} position: {0, 0.5}
			transparency: 0.5 {
				list<int> values <- [Crit_bilan_humain, Crit_bilan_materiel_public, Crit_bilan_materiel_prive];
				list<point> points <- world.define_surface3(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: 2 {
					float angle <- (first(axis3[i].points) towards last(axis3[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i])  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}

			
			chart "global" type:histogram size: {0.4,0.4} position: {0.5, 0}
			series_label_position: xaxis
			y_range:[0,5]
			 y_tick_unit:1
			{
				data "Attractivité" value:min([Crit_logement, Crit_infrastructure, Crit_economie])
				color:#yellow;
				data "Sécurité" value:min([Crit_bilan_humain, Crit_bilan_materiel_prive, Crit_bilan_materiel_public])
					color:#red;
				data "Développement durable" value:min([Crit_sols, Crit_satisfaction, Crit_environnement])
				color:#green;
			}
		
		
		}
		
		}
		
}
		

	
	
	
	
	
	experiment Interation type: gui {
	output {
			layout horizontal([0.0::7285,1::2715]) tabs:true;
		display map type: opengl background: #black draw_env: false refresh:true{
			species cell  refresh: true aspect:map;
			species green_area;
			//species natura;	
			species building;
			species road;
			species parking;
			species obstacle;
			species river;
		//	species pluvial_network;
			species people;
			species car;
			species project;
		//	event mouse_down action:cell_management;

			overlay position: { 5, 5 } size: { 250 #px, 80 #px } background: # black transparency: 0.5 border: #black rounded: true
            {  
                    draw date_in at: { 40#px, 20#px + 4#px } color: # white font: font("Helvetica", 18, #bold);
                     draw nb_blesse at: { 40#px, 40#px + 4#px } color: # white font: font("Helvetica", 18, #bold);
                      draw nb_mort at: { 40#px, 60#px + 4#px } color: # white font: font("Helvetica", 18, #bold);
            }
			
		}
		//display the action buttons
		display action_buton background:#black name:"Projets"  	{
			species button aspect:normal ;
			event mouse_down action:activate_act;    
		}
		
		
		display map3D type: opengl background: #black draw_env: false {
			grid cell  triangulation:false refresh: true ;
			species cell  refresh: true aspect:map3D;				
		}
		
		
		display "Indicateurs"
		{
			
		
		
			//Attractivité
			graphics "radars axis" 
			size: {0.4,0.4}  position: {0, 0}
			refresh: false{
					loop i from: 0 to:2 {
					geometry a <- axis3[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * 1.1;
					draw axis_labelAtt[i]  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}

			graphics "radars surface" 
			size: {0.4,0.4} position: {0, 0}
			transparency: 0.5 {
				list<int> values <- [Crit_logement, Crit_infrastructure, Crit_economie];
				list<point> points <- world.define_surface3(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: 2 {
					float angle <- (first(axis3[i].points) towards last(axis3[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i])  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
		
		
		
			
			//Développement durable
			graphics "radars axis" 
			size: {0.4,0.4} position: {0.4, 0.5}
			refresh: false{
					loop i from: 0 to: 2 {
					geometry a <- axis3[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * 1.1;
					draw axis_labelDD[i]  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}

			graphics "radars surface" 
			size: {0.4,0.4} position: {0.4, 0.5}
			transparency: 0.5 {
				list<int> values <- [Crit_sols, Crit_satisfaction, Crit_environnement];
				list<point> points <- world.define_surface3(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: 2 {
					float angle <- (first(axis3[i].points) towards last(axis3[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i])  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
		
		
		
			//Sécurité
			graphics "radars axis" 
			size: {0.4,0.4} position: {0, 0.5}
			refresh: false{
					loop i from: 0 to: 2 {
					geometry a <- axis3[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis3[i].points) + (last(axis3[i].points) - first(axis3[i].points)) * 1.1;
					draw axis_labelSec[i]  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}

			graphics "radars surface" 
			size: {0.4,0.4} position: {0, 0.5}
			transparency: 0.5 {
				list<int> values <- [Crit_bilan_humain, Crit_bilan_materiel_public, Crit_bilan_materiel_prive];
				list<point> points <- world.define_surface3(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: 2 {
					float angle <- (first(axis3[i].points) towards last(axis3[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i])  at: pt anchor: #center font: font("Helvetica", 10, #bold) color: #black;
					
				}
			}
	
	
	
		
		
	/*	chart "Développement durable" size: {0.4,0.4} position: {0.4, 0.5} type: radar x_serie_labels: ["Cycle de l'eau", "Satisfaction de la population", "Biodiversité", "max"]  
			{
				data "Situation actuelle" value: [Crit_cycle_eau, Crit_satisfaction, Crit_biodiversite] color: #yellow;
				data "Situation de départ" value: [2, 2, 2] color: #blue;
			}
 
	chart "Sécurité" size: {0.4,0.4} position: {0, 0.5} type: radar x_serie_labels: ["Bilan humain", "Bilan matériel", "reconstruction"]  
			{
				data "Situation actuelle" value: [Crit_bilan_humain, Crit_bilan_materiel, Crit_reconstruction] color: #yellow;
				data "Situation de départ" value: [2, 2, 2] color: #blue;
			}
		
		chart "Attractivité du territoire"  size: {0.4,0.4} position: {0, 0} type: radar x_serie_labels: ["Environnement", "Logement", "Infrastructure", "Economie"] 
				y_range:[0,5]
			 y_tick_unit:1
			{
				data "Situation actuelle" value: [Crit_environnement, Crit_logement, Crit_infrastructure, Crit_economie] color: #yellow;
				data "Situation de départ" value: [2, 2, 2, 2] color: #blue;
			}
	*/	

			
			chart "global" type:histogram size: {0.4,0.4} position: {0.5, 0}
			series_label_position: xaxis
			y_range:[0,5]
			 y_tick_unit:1
			{
				data "Attractivité" value:min([Crit_logement, Crit_infrastructure, Crit_economie])
//				style:stack
				color:#yellow;
				data "Sécurité" value:min([Crit_bilan_humain, Crit_bilan_materiel_prive, Crit_bilan_materiel_public])
//				style: stack
					color:#red;
				data "Développement durable" value:min([Crit_sols, Crit_satisfaction, Crit_environnement])
//				style: stack  
				color:#green;
				//marker_shape:marker_circle ;
			}
		
		
		}
		
		
	}
}
