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
float toto;
//	file mnt_file <- grid_file("../includes/LCred4.asc");
	file mnt_file <- grid_file("../results/grid2.asc");
	file my_data_flood_file <- csv_file("../includes/data_flood3.csv", ",");
	file my_data_rain_file <- csv_file("../includes/data_rain.csv", ",");
	shape_file res_buildings_shape_file <- shape_file("../results/residential_building.shp");
	shape_file market_shape_file <- shape_file("../results/market.shp");
	shape_file erp_shape_file <- shape_file("../results/erp.shp");
	shape_file main_roads_shape_file <- shape_file("../results/main_road.shp");
	shape_file roads_shape_file <- shape_file("../results/city_roads.shp");
	shape_file highway_shape_file <- shape_file("../results/highway.shp");
	//shape_file roads_shape_file <- shape_file("../results/roads.shp");
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
	
	
	
	//shape_file population_shape_file <- shape_file("../includes/city_environment/population.shp");
	
	geometry shape <- envelope(mnt_file);

	string alea;
	string scenario;
	
	map<list<int>,	graph> road_network_custom;
	map<road, float> current_weights;
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
	
		
	float water_height_perception <- 1 #cm;
	float water_height_danger_inside_energy_on <- 20 #cm;
	float water_height_problem <- 5 #cm;
	float water_height_danger_inside_energy_off <- 50 #cm;

	float river_broad_maint <- 0.01 #m;
	float river_depth_maint<- 0.01 #m;
	float river_broad_normal<- 0.01#m;
	float river_depth_normal<-0.01#m;
	float river_depth_max<-1#m;
	float canal_deb_init <- 0.4;
	float canal_deb_maint <- 0.8;
	
	float max_speed <- 5 #m/#s;
	int repeat_time;
	float Vmax<-3#m/#s;
	

	bool end_simul<-false;
	int leaving_people <- 0;

	bool mode_flood<-false;
	
	list<cell> flooded_cell;
	int nb_flooded_cell;
	
	list<cell> active_cells;
	list<cell> escape_cells;
	list<cell> river_cells;
	
	float strength_information_decrement <- 0.1;
	
	list<road> safe_roads ;
	
	float cumul_water_enter;
			
	
	float fear_contagion_distance <- 2.0 #m;

	float flooded_road_percep_distance <- 20#m;
	
	float threshold_fear_intensity <- 0.8;
	float life_at_stake_water_here <- 10^(-7)/#mn * step;
	float life_at_stake_water_at_my_door <- 10^(-6)/#mn * step;
	float life_at_stake_house_flooded <- 10^(-5)/#mn * step;
	float coeff_life_at_stake_water_increase <- 0.03*#mn * step;
	
	int max_number_to_inform <- 10;
	
	bool rain<-false;
	bool water_input<-true;
	bool water_test<-true;
	
	float time_flood_test<-2#h;
	float time_simulation<-3#h;
	
	bool scen<-false;      //active ou desactive l'écran de selection des scnéario
	bool creator_mode<-true;
	bool only_flood<-false;
	bool nothing_more<-false;
	int model_flow<-2; //1: siflo, 2:simplified, 3:other simplified
	float rain_intensity_test<-3 #cm;
	float initial_water_level<-10^6;
	float water_input_test<-10*10^6#m3/#h;
	float default_plu_net<-0.1#m3/#s;
	
	bool plu_mod<-false;
	list<rgb> color_category <- [#darkgrey, #gold, #red];
	
	map<people,string> injured_how;
	map<people,string> dead_how;
 
 
 
	int flooded_building;
	float average_building_state;

 

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
	//beliefs*******************************************************
	
	predicate life_at_stake <- new_predicate("life is at stake");
	predicate life_not_at_stake <- new_predicate("life is at stake", false);
	predicate house_flooded <- new_predicate("house_flooded");
	predicate water_at_my_door <- new_predicate("water_at_my_door");
	predicate evacuation_is_possible <- new_predicate("evacuation_is_possible");
	predicate property_protected <- new_predicate("property_protected");
	predicate property_impermeable <- new_predicate("property_impermeable");
	predicate water_is_here <- new_predicate("water_is_here");
	predicate water_is_coming <- new_predicate("water_is_coming");
	predicate need_to_go_outside <- new_predicate("need_to_go_outside");
	predicate someone_to_help <- new_predicate("someone_to_help");
	predicate vulnerable_properties <- new_predicate("vulnerable_properties");
	predicate vulnerable_car <- new_predicate("vulnerable_car");
	predicate vulnerable_building <- new_predicate("vulnerable_building");
	predicate energy_is_on <- new_predicate("energy_is_on");
	predicate energy_is_dangerous <- new_predicate("energy_is_dangerous");
	predicate crisis_event <- new_predicate("crisis_event");

	//intention
	predicate drain_off <- new_predicate("drain_off");
	predicate evacuate <- new_predicate("evacuate");
	predicate inform <- new_predicate("inform");
	predicate outside <- new_predicate("outside");
	predicate upstairs <- new_predicate("upstairs");
	predicate inquire <- new_predicate("inquire");
	predicate protect_car <- new_predicate("protect_car");
	predicate protect_properties <- new_predicate("protect_properties");
	predicate turn_off <- new_predicate("turn_off");
	predicate protect <- new_predicate("protect");
	predicate weather_strip <- new_predicate("weather_strip");
	predicate wait <- new_predicate("wait");
	predicate apply_instructions <- new_predicate("apply_instructions");
	predicate do_nothing <- new_predicate("do_nothing");
	
	int nb_waiting update: length(people);
	int nb_drain_off update: 0;
	int nb_evacuate update: 0;
	int nb_inform update: 0;
	int nb_outside update: 0;
	int nb_upstairs update: 0;
	int nb_inquire update: 0;
	int nb_protect_car update: 0;
	int nb_protect_properties update: 0;
	int nb_turn_off update: 0;
	int nb_weather_strip update: 0;
	
	list<road> not_usable_roads update: [];
	
	bool parallel_computation <- false;
	bool verbose <- false;
	bool benchmark <- false;
	
	
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
		if benchmark {t <- machine_time;}
		step <-  time_step; 
		ratio_received_water <- 1.0;
		
		
		do create_buildings_roads;
		do create_project;
		if verbose {write "Building and roads created: " + length(building);}
		create institution;
		
		
		//do load_parameters;

		do create_natural_environment;
		do initiate_plu;
		
		if verbose {write "Natural environment created";}
		ask cell {
			do update_color;
			cell_area<-shape.area;
		}
		
		
		
		
		
		if verbose {write "Spe Riv created";}
		
		data_flood <- matrix(my_data_flood_file);
		data_rain <- matrix(my_data_rain_file);
		river_origin <- (river with_min_of (each.location.x));
		river_ending <- (river with_max_of (each.location.x));
	
		do init_cells_and_bd_select;
	
	
		if verbose {write "Data loaded and cell initiliazed";}	
		//safe_roads <- road where empty(active_cells overlapping each);
		safe_roads <-road where (each.category=0);
		// where ((each distance_to rivers) > 100#m );
		//empty(active_cells overlapping each);
		
		road_network_custom[list<int>([])] <- (as_edge_graph(road) use_cache false) with_shortest_path_algorithm #NBAStar;
		current_weights <- road as_map (each::each.shape.perimeter);

		//	create people from: population_shape_file; 
		//	write length(building where (each.category=0));
		
		
		if verbose {write "Road network computed";}	
		
		if benchmark {
			do add_data_benchmark("World init - environment", machine_time - t);
			t <- machine_time;
		}
		
		if !only_flood {
			do create_people;
		}
		
		if benchmark {
			do add_data_benchmark("World init - create people", machine_time - t);
			t <- machine_time;
		}
		
		
		repeat_time<-round(max_speed *step/sqrt(cell_area));
		do manage_scenario;
	
		if verbose {write "Scenario initialized";}	
		
		if benchmark {
			do add_data_benchmark("World init - init scenario", machine_time - t);
		}
		
	
	}
	
	
		action create_project {
		create project from: bassin_shape_file;
		write length(project);
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
			altitude <- (my_cells mean_of (each.grid_value));
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
				if altitude>100#m {altitude<-altitude-20#m;}
			}
			
			altitude <- (my_cells mean_of (each.grid_value));
			my_location <- location + point(0, 0, altitude + 1 #m);
			cell_origin <- (my_cells with_max_of (each.grid_value));
			cell_destination <- (my_cells with_min_of (each.grid_value));
			river_length <- shape.perimeter;
			ask my_cells {
				water_height <- myself.river_height;
				is_river <- true;
			}

		}
		
		
			float prev_alt<-500#m;
	 	loop riv over:river_cells sort_by (each.location.x){
				riv.river_broad<-river_broad_normal;
				riv.altitude<-min([prev_alt+0.5#m,riv.altitude]);			
				prev_alt<-riv.altitude;
				ask riv.neighbors where (!each.is_river and each.altitude>prev_alt) {
		//			altitude<-(altitude+2*prev_alt)/3; 
					already<-true;
					float alt<-altitude;
					ask neighbors where (!each.is_river and !each.already and each.altitude>alt) {//altitude<-(altitude+2*alt)/3;
						float alt2<-altitude;
						already<-true;
						ask neighbors where (!each.is_river and !each.already and each.altitude>alt2) {//altitude<-(altitude+2*alt2)/3;
							float alt3<-altitude;
							already<-true;
				ask neighbors where (!each.is_river and !each.already and each.altitude>alt3) {//altitude<-(altitude+2*alt3)/3;
							float alt4<-altitude;
							already<-true;
				ask neighbors where (!each.is_river and !each.already and each.altitude>alt4) {//altitude<-(altitude+2*alt4)/3;
							already<-true;
				
				}
						
				}
						
				}
				
				
				}
				
				}
		}
		
		prev_alt<-500#m;
		loop riv over:river_cells sort_by (each.location.x*100+each.location.y){
				riv.river_altitude<-max([0,min([riv.altitude-river_depth_normal,prev_alt-20#cm])]);
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
			if grid_value < 0 {
				is_sea <- true;
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
			active_cells <- cell where (((each.location distance_to rivers) <= max_distance_to_river));
			ask active_cells {
				is_active <- true;
			}

		}
		ask building where ((each distance_to rivers) > max_distance_to_river ) {
			do die;
		}
		
		
	
		
	}
	
	action create_people {
		ask building where (each.category=0) {
			float it_max<-shape.area/50;
			int it<-0;
			
			loop while: it<it_max {
			create people {
				location<-myself.location;
				my_building<-myself;
				current_stair <- rnd(my_building.nb_stairs);
			
				
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
		
		
	/* 	ask people parallel: parallel_computation{
	 
			know_rules <- flip(one_of(institution).DICRIM_information);
			do add_desire(life_not_at_stake, 1.0);
			do add_desire(do_nothing, strength_do_nothing);
			//values from Schmitt, D. P., Allik, J., McCrae, R. R., & Benet-Martínez, V. (2007). The geographic distribution of Big Five personality traits: Patterns and profiles of human self-description across 56 nations. Journal of cross-cultural psychology, 38(2), 173-212.
			extroversion <- max(0.0,min(1.0,gauss(45.44,8.77) / 100.0));
			agreeableness <- max(0.0,min(gauss(46.64,8.19) / 100.0));
			conscientiousness <- max(0.0,min(gauss(49.26,10.23) / 100.0));
			neurotism <- max(0.0,min(gauss(52.29,9.34) / 100.0));
			openness <- max(0.0,min(gauss(48.09,9.52) / 100.0));
			obedience_init <- sqrt((agreeableness + conscientiousness) /2.0);
			obedience <- obedience_init - 0.1;
			friends_to_inform_to_select <- round(max_number_to_inform * extroversion);
		*/	
			/*list<building> bds <- building overlapping self;
			if empty(bds) {
				do die;
			} else {
				my_building <- first(bds);*/
				
				//location <- location + {0, 0, my_building.bd_height};
	/* 			float proba_info<-one_of(institution).flood_informed_people;
				if flip(proba_info) {
					do add_belief(water_is_coming);
				}*/
			//}
/*
			current_stair <- rnd(my_building.nb_stairs);
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
				
				
			/* 	if (cell(my_car.location) in active_cells) {
					do add_belief(vulnerable_car);
				}

			} else {
				strength_protect_car <- 0.0;
			}
			
			if flip(0.3) {
				do add_belief(energy_is_dangerous);
			}
			do add_belief(crisis_event);
			do add_belief(energy_is_on);
			do add_belief(evacuation_is_possible);
		
		}*/
		
		/*	ask parking {
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
				
					
				}*/
		/* 
		nb_waiting <- length(people);
 		nb_people_begin<- length(people);
		if verbose {write "People created: " + nb_people_begin;}	
		
		list<people> to_inform <- people where (each.friends_to_inform_to_select > 0);
		ask people {
			if (friends_to_inform_to_select > 0) {
				friends_to_inform <- round(max_number_to_inform * extroversion) among to_inform;
				loop f over: friends_to_inform {
					float appreciation <- rnd(0.0,1.0);
					float solidarity <- rnd(0.0,1.0);
					social_link relation <- new_social_link(f, appreciation, 0.0, solidarity, 0.0);
					do add_social_link(relation );
					ask f {
						friends_to_inform_to_select <- friends_to_inform_to_select - 1;
						do add_social_link(new_social_link(myself,rnd(0.0, 1.0), 0.0, rnd(0.0, 1.0),0.0));
					}
						
				}
				to_inform <- to_inform - (friends_to_inform where (each.friends_to_inform_to_select = 0));
			}
		} 
		if verbose {write "People network generated";}	*/
		
	
	
/*	}*/
	
	action manage_scenario {
		if scen {
			 map input_values <-user_input_dialog("Quel scénario voulez vous simuler ? ",[choose("Scénario",string,"statu quo",["statu quo","population informée","rivière élargie"]),choose("Alea",string,"moyen",["petit","moyen","fort"])]);
			 alea<-(input_values at "Alea");
			 scenario<-(input_values at "Scénario");
			 
			 rain<-false;
		 	 water_input<-true;
			 water_test<-true;
	
			if alea="petit" {water_input_test<-1*10^2#m3/#h;}
			if alea="moyen" {water_input_test<-5*10^5#m3/#h;}
			if alea="fort" {water_input_test<-1*10^6#m3/#h;	}
			
			
			if scenario="statu quo" {}
			if scenario="population informée" {ask institution {DICRIM_information<-1.0;}	}
			if scenario="rivière élargie" {ask cell where (each.is_river) {river_broad<-river_broad+2#m;}	}
	
		}
		
		ask cell {do compute_permeability;}
		do create_spe_riv;
		
	write ("nb d'habitants : "+length(people)*2.3);
	write ("superficie du territoire :"+ world.shape.area #km);
	write ("altitude maximale :"+ cell max_of(each.altitude));
	
	if nothing_more {
		ask building {do die;}
		ask road {do die;}
		ask green_area {do die;}
		ask parking {do die;}
		ask natura {do die;}
	}
		
		
		
	}
	
//***************************  END of INIT     **********************************************************************


	//***************************  REFLEX GLOBAL **********************************************************************
	float time_start;
	reflex mode {
	if mode_flood {
		ask people {do acting;}
		if (time mod 30#mn) = 0 {do garbage_collector;}   //every(30 #mn)
		if (time mod 60#mn) = 0 {do update_flood;} //every(#hour) 
		do flower;
		do update_road;
		if (time mod display_every) = 0 {if benchmark{do write_benchmark;}}
		if (time=time_start+3600*3) {
			mode_flood<-false;
			do update_indicators; 
			ask cell {
				water_volume<-0.0;
				do compute_water_altitude;	
				do verify_river_full;
			}
			write "Morts : "+dead_people;
			write "Blessés : "+injuried_people;
			write ("number of flooded car : " +flooded_car);
			write ("number of flooded building: " +flooded_building);
		}
		
	}	
	
	if !mode_flood {
		write ("Mode Gestion");
		do pause;
		mode_flood<-true;
		time_start<-time;
	}
	
	}
	
	action garbage_collector  {
		ask experiment {do compact_memory;}
	}
	
	action update_flood {
		float t; if benchmark {t <- machine_time;}
		flooded_building<-length(building where (each.serious_flood));
		average_building_state<-mean(building collect each.state);
		flooded_car<-length(car where (each.domaged));
		float proba_know_rules<-one_of(institution).DICRIM_information;

	
		
		
	/* 	string 	results <- ""+ 
		int(self)+"," + seed+","+scenario+","+ proba_know_rules + ","+river_broad+","+
		river_depth+","+","+ cycle + ","+
		leaving_people+"," +injuried_people+","+injuried_people+","+dead_people+","+
		dead_people+"," +flooded_car+"," +flooded_building+","+average_building_state +"," +injured_how.values+ ","+ dead_how.values ;
		
		save results to: "results_" + type_explo+ "_" + scenario+".csv" type:text rewrite: false;
*/		
		//if (increment = data_flood.rows or increment = data_rain.rows) {
		if (time=time_simulation) {
			nb_flooded_cell<-length(flooded_cell);
			write ("*************************");
			write ("number of people : ") +nb_people_begin;
			write ("number of evacuated people : " +leaving_people);
			write ("number of injuried people inside : " +injuried_people);
			write ("number of injuried people outside : " +injuried_people);
			write ("number of dead people in building: " +dead_people);
			write ("number of dead people outside: " +dead_people);
			write ("number of flooded car : " +flooded_car);
			write ("number of flooded building: " +flooded_building);
			write ("average building state: " +average_building_state);
			write ("injured during which activity: " +injured_how.values);		
			write ("dead during which activity: " +dead_how.values);
			write ("flooded cell : "+nb_flooded_cell);
			
			end_simul<-true;
			do pause;
		}
		
		increment <- increment + 1;
		if benchmark {
			do add_data_benchmark("World - update_flood", machine_time - t);
		}
	
	}


action flower {
ask cell where (each.water_height>1#cm and each.is_pluvial_network) {
	water_volume<-max([0,water_volume-water_evacuation_pl_net*step]);
}
ask cell where (length(each.neighbors)<8) {
water_volume<-max([0,water_volume*length(neighbors)/8]);
}
if model_flow=1 {do flowing1;}
if model_flow>1 {do flowing2;}
ask cell where (each.is_dyke and each.water_height>1#m) {do breaking_dyke;}

}


	action flowing1 {
		float t; if benchmark {t <- machine_time;}
		float tt; if benchmark {tt <- machine_time;}
		
		float hmax<-cell max_of(each.water_height);
		Vmax<-0.0;
		if rain {
			ask cell where !each.is_sea {
			 	float rain_intensity <- float(data_rain[0, increment]) #mm;
				if water_test and time<=time_flood_test{ rain_intensity <- rain_intensity_test;
				}
				water_height<-water_height+rain_intensity*step/1#h;
				water_volume<-water_height*cell_area;
				do compute_water_altitude;
			}
		
		}
		
		if benchmark {do add_data_benchmark_sub("World - flowing - step 1", machine_time - tt);tt <- machine_time;}
		if water_input {
		//	float debit_water <- float(data_flood[0, increment]) #m3/#h;
		//	initial_water_level <- debit_water *step;
		//	if water_test and time<=time_flood_test{	
		//		initial_water_level <- water_input_test*step/cell_area;
		//	}
			
			
			ask cell where (each.location.x=1 and each.location.x=1) {
						cumul_water_enter<-cumul_water_enter+initial_water_level;
						write "cumul wat : "+	cumul_water_enter;
					water_volume<-water_volume+initial_water_level;
					do compute_water_altitude;
			} 
		/* 	ask river_origin {
				ask cell_origin  parallel: parallel_computation{
					cumul_water_enter<-cumul_water_enter+initial_water_level;	
					water_volume<-water_volume+initial_water_level;
					do compute_water_altitude;
								
				}
				
			}*/
		}
		if benchmark {do add_data_benchmark_sub("World - flowing - step 2", machine_time - tt);tt <- machine_time;}
		
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
		if benchmark {do add_data_benchmark_sub("World - flowing - step 3", machine_time - tt);tt <- machine_time;}
		
		loop times:repeat_time {
			float ttt; if benchmark {ttt <- machine_time;}
			ask active_cells parallel: parallel_computation{
				already <- false;
				if water_altitude=0.0 {already <- true;}
				do compute_water_altitude;
			}
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 1", machine_time - ttt);ttt <- machine_time;}
		
			list<cell> flowing_cell <- active_cells where (each.water_altitude > 0);
			list<cell> cells_ordered <- flowing_cell sort_by (each.water_altitude);
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 2", machine_time - ttt);ttt <- machine_time;}
		
			ask cells_ordered {
				do flow;
			}
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 3", machine_time - ttt);ttt <- machine_time;}
		
			ask remove_duplicates((active_cells where (each.water_height > 0)) accumulate each.my_buildings) parallel: parallel_computation{do update_water;}
			ask car parallel: parallel_computation{do update_state;}
			ask road parallel: parallel_computation{do update_flood;}
			ask people parallel: parallel_computation{do update_danger;}
			flooded_cell<-remove_duplicates(flooded_cell);
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 4", machine_time - ttt);ttt <- machine_time;}
				
		}
		if benchmark {do add_data_benchmark_sub("World - flowing - step 4", machine_time - tt);tt <- machine_time;}
		
		ask building  parallel: parallel_computation {do update_water_color;}
			
		
		float max_wh_bd <- max(building collect each.water_height);
		float max_wh <- max(cell collect each.water_height);
		ask cell  parallel: parallel_computation {do update_color;}
		if benchmark {do add_data_benchmark_sub("World - flowing - step 5", machine_time - tt);tt <- machine_time;}
		
		if benchmark {do add_data_benchmark("World - flowing", machine_time - t);}
	}


	action flowing2 {
		float volume_wat_tot<-cell sum_of(each.water_volume);
		write volume_wat_tot;
		
		float t; if benchmark {t <- machine_time;}
		float tt; if benchmark {tt <- machine_time;}
		
		float hmax<-cell max_of(each.water_height);
		Vmax<-0.0;
		if rain {
			ask active_cells where !each.is_sea parallel: parallel_computation {
			// 	float rain_intensity <- float(data_rain[0, increment]) #mm;
					float rain_intensity <- rain_intensity_test;
				water_height<-water_height+rain_intensity*step/1#h;
				 	water_volume<-water_height*cell_area;
					do compute_water_altitude;
	
			}
		
		}
		
		if benchmark {do add_data_benchmark_sub("World - flowing - step 1", machine_time - tt);tt <- machine_time;}
		if water_input {
			float debit_water <- float(data_flood[0, increment]) #m3/#h;
			initial_water_level <- debit_water *step;
			if water_test and time<=time_flood_test{	
				initial_water_level <- water_input_test*step/cell_area;
			}
			
			
	/* 		ask cell where (each.grid_x=0 and each.grid_y=0) {
						cumul_water_enter<-cumul_water_enter+initial_water_level;	
					water_volume<-water_volume+initial_water_level;
					do compute_water_altitude;
			} */
		 	ask river_origin {
				ask cell_origin  parallel: parallel_computation{
					cumul_water_enter<-cumul_water_enter+initial_water_level;	
					water_volume<-water_volume+initial_water_level;
					write "vvvvvvvv";
				//	write "init : "+initial_water_level;
				//	write " wat vol : "+water_volume;
					write "tot vol : "+ cell sum_of(each.water_volume);
					write "tot vol : "+ cell min_of(each.water_volume);
				//
					write " cumul_water_enter : "+cumul_water_enter;
					write "vvvvvvvv";
					
					do compute_water_altitude;
								
				}
				
			}
		}
		if benchmark {do add_data_benchmark_sub("World - flowing - step 2", machine_time - tt);tt <- machine_time;}
		
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
		if benchmark {do add_data_benchmark_sub("World - flowing - step 3", machine_time - tt);tt <- machine_time;}
		
		
		
			float ttt; if benchmark {ttt <- machine_time;}
			ask cell parallel: parallel_computation{
				if water_volume<=0.0 {already <- true;}
				else {
					already <- false;
					do compute_water_altitude;
			}
			}
			
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 1", machine_time - ttt);ttt <- machine_time;}
		
			list<cell> flowing_cell <- cell where (each.water_volume>1 #m3);
			list<cell> cells_ordered <- flowing_cell sort_by (each.water_altitude);
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 2", machine_time - ttt);ttt <- machine_time;}
		
			ask cells_ordered {
				if model_flow=2 {do flow2;}
				if model_flow=3 {do flow3;}
			}
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 3", machine_time - ttt);ttt <- machine_time;}
		
			ask remove_duplicates((active_cells where (each.water_height > 0)) accumulate each.my_buildings) parallel: parallel_computation{do update_water;}
			ask car parallel: parallel_computation{do update_state;}
			ask road parallel: parallel_computation{do update_flood;}
			ask people parallel: parallel_computation{do update_danger;}
			flooded_cell<-remove_duplicates(flooded_cell);
			if benchmark {do add_data_benchmark_sub("World - flowing - step 4 sub_step 4", machine_time - ttt);ttt <- machine_time;}
				
		
		if benchmark {do add_data_benchmark_sub("World - flowing - step 4", machine_time - tt);tt <- machine_time;}
		
		ask building  parallel: parallel_computation {do update_water_color;}
			
		
		float max_wh_bd <- max(building collect each.water_height);
		float max_wh <- max(cell collect each.water_height);
		ask cell  parallel: parallel_computation {do update_color;}
		if benchmark {do add_data_benchmark_sub("World - flowing - step 5", machine_time - tt);tt <- machine_time;}
		
		if benchmark {do add_data_benchmark("World - flowing", machine_time - t);}
	}

	action update_road {
		float t; if benchmark {t <- machine_time;}
		
		current_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
		if benchmark {
			do add_data_benchmark("World - update_road", machine_time - t);
		}
	}
	
	action write_benchmark {
		write "\nCycle:" + cycle + " Total time taken (in s) : " + ((machine_time - init_time) / 1000.0) + " - measured: " + (sum(time_taken_main.values) / 1000.0) ;
		write " ** Main step :";
		loop id over: (time_taken_main.keys) sort_by (-1 * time_taken_main[each]){
			write id +" : " + (time_taken_main[id] / 1000.0); 
		}
		write " ** Sub step:";
		loop id over: (time_taken_sub.keys) sort_by (-1 * time_taken_sub[each]){
			write id +" : " + (time_taken_sub[id] / 1000.0); 
		}
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
bien_endommage<-0.5; //à calculer
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
	else {if flooded_car<15 {Crit_bilan_materiel_prive3<-3;}
		else {if flooded_car<50 {Crit_bilan_materiel_prive3<-2;}
			else {if flooded_car<100 {Crit_bilan_materiel_prive3<-1;}
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



ask road where (each.is_flooded) {is_flooded<-false;}
ask building where (each.serious_flood) {serious_flood<-false;}
ask car where each.domaged {domaged<-false;}
ask people where each.injuried {injuried<-false;}
injuried_people<-0;
dead_people<-0;


//;
//  biodiversite_crit;


/*Environnement
Logement; //0: nul à 5 : top
Infrastructure; //0: nul à 5 : top
Economie; //0: nul à 5 : top

*/


/*float entreprise;
float budget_env;

int dead_people <- 0;
int  <- 0;
int injuried_people;
int injuried_people;
int 
float average_building_state;
int flooded_car;
float flooded_road;
float delai_rep_reseaux;
float delai_rep_bat;
float taux_desimper; //nécessaire ?
float taux_artificilisation;
float satisfaction;

float biodiversite;*/
}

//******************************** USER COMMAND ****************************************


	//current action type
	int action_type <- -1;	
	bool second_point<-false;
	point first_location;
	
	//images used for the buttons
	list<file> images <- [
		file("../images/digue.png"),
		file("../images/building.jpg"),
		file("../images/building_demol.png"),
		file("../images/alarm.jpg")
	]; 
	
	action activate_act {
	/*	button selected_but <- first(button overlapping (circle(1) at_location #user_location));
		if(selected_but != nil) {
			ask selected_but {
				ask button {bord_col<-#black;}
				if (action_type != id) {
					action_type<-id;
					bord_col<-#red;
				} else {
					action_type<- -1;
				}
				
			}
			if action_type=3 {
				write "waaaaaoooooooouhhhhhh waaaaouhhhhhhh";
				ask people {do add_belief(water_is_coming);	}
			}
		}*/
	}

	action cell_management {
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



}

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
//***************************  Projets    **********************************************************************
//***********************************************************************************************************
species project {
int Niveau_act;

	aspect default {
		draw shape color:#orange;
		
	}
}






//***********************************************************************************************************
//***************************  ROAD    **********************************************************************
//***********************************************************************************************************
species road {
	rgb color;
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

		val_water <- max([0, min([255, int(255 * (1 - (cell_water_max / 3.0)))])]);
		color <- rgb([255, val_water, 0]);
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
	car my_car;
	bool have_car;
	int Age;
	string Sexe;
	string iris;
	string Couple;
	string CSP;
	
	int current_stair;
	bool know_rules;
	point my_location;
	bool in_car <- false;
	bool inside<-true;
	bool injuried<-false;

	int friends_to_inform_to_select;
	list<people> friends_to_inform;
	
	float satisfaction<-0.5; //0: not satisfy at all, 1: very satisfied
	
	
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
	point current_target;
	point final_target;
	point random_target;
	building random_building;
	rgb my_color <- #mediumvioletred;
	bool return_home <- false;
	
	list<int> known_blocked_roads;
	
	graph current_graph;
	
	float outside_test_period <- rnd(15,30) #mn;
	cell my_current_cell;
	
	float water_level <- 0.0;
	
	float prev_water_inside <- 0.0;
	float prev_water_outside <- 0.0;
	
	
	float max_danger_inside<-0.0;
	float max_danger_outside<-0.0;
	
	bool doing_agenda<-false;
	
	init {
		if flip(0.2) {
			doing_agenda<-true;
			final_target <- (one_of(building where (each.category>0))).location;
		}
		
		
		
	}

	action acting {
		if (time mod 10#mn) = 0 {do test_proba;} //when: (time mod 10#mn) = 0
		do my_perception;
		if (doing_agenda) {do agenda;}
	}
	
	
	
	//***************************  perception ********************************
	action my_perception {
		if mode_flood {
		bool water_cell_neighbour <- false;
		bool water_cell <- false;
		bool water_building <- false;
		danger_inside<-0.0;
		danger_outside<-0.0;
		if inside {
			float whp <- water_height_perception;
			water_cell <- my_building.water_cell;
			water_cell_neighbour <- my_building.neighbour_water;
			water_level <- my_building.water_height;
			prev_water_inside <- my_building.water_height ;
		
			if my_building.water_height >= water_height_problem {
				water_building <- true;
				if current_stair<my_building.nb_stairs {current_stair<-my_building.nb_stairs;}
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
						if not (self in injured_how.keys) {
							injuried<-true;
							injuried_people <- injuried_people+1;
						}
					}
				}		
		}
		else if my_current_cell != nil{
			float wh<-my_current_cell.water_height; 
			if in_car {danger_outside<-max([danger_outside,max([0,min([1.0, (wh-water_height_danger_car)/water_height_danger_car])])]);	}
			else {danger_outside<-max([danger_outside,max([0,min([1.0, (wh-water_height_danger_pied)/water_height_danger_pied])])]);}
			if danger_outside >0 {
				max_danger_outside <- max(max_danger_outside, danger_outside);		
				if not (self in injured_how.keys) {
					injuried<-true;
					injuried_people <- injuried_people+1;
				}			
			}
		}
	}
	
	action test_proba  {
		if flip(max_danger_outside) or flip(max_danger_inside) {
			do to_die;
		}
		max_danger_inside <- 0.0;
		max_danger_outside <- 0.0;
	}
	
		
	action agenda{
			if (final_target = nil) {
				final_target <- (one_of(building where (each.category>0))).location;
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
					leaving_people <- leaving_people + 1;
					if (in_car) {ask my_car {do die;}}
					do die;
				} else {
					in_car <- true;
					current_target <- final_target;
				}
			}
		}
		
		if flip(0.3) {do moving;}
	}
	
	
	
	action to_die {
		if (inside) {
			dead_people <- dead_people + 1;
		} else {
			dead_people <- dead_people + 1;
		}

			if (injuried) {
				injuried_people <- injuried_people - 1;
			}
	
	
		do die;
	}
	


	


	action moving {
		inside<-false;
		list<road> rd <- not_usable_roads where ((each distance_to self) < flooded_road_percep_distance) ;
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
		
		}
		if (current_graph = nil) {current_graph <- road_network_custom[known_blocked_roads];}
		do goto target: current_target on: current_graph = nil ? first(road_network_custom.values) :  current_graph move_weights: current_weights ;
		if (location = current_target) {
			current_graph <- nil;
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
	

	action do_nothing  {
			
	}

	action drain_off_water  {
		my_building.water_height <- max([0, my_building.water_height - 0.01 #m3 / #mn / my_building.shape.area * step]);
		current_stair <- 0;
	}


	action evacuate  {
		current_stair<-0;
		inside<-false;
		my_color <- #gold;
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
					leaving_people <- leaving_people + 1;
					if (in_car) {ask my_car {do die;}}
					do die;
				} else {
					in_car <- true;
					current_target <- final_target;
				}
			}
		}
	}


	action give_information {
	}


	action go_outside  {
		current_stair<-0;		
		inside<-false;
		my_color <- #pink;
		speed <- my_speed();
		if (random_target = nil) {
			random_building<-one_of (building);
			random_target <- (random_building.location);
			if (have_car) {
				current_target <- my_car.location;
			} else {
				current_target <- random_target;
			}

		} else {
			do moving;
			if( in_car) {
				my_car.location <- location;
			}
			if (current_target = location) {
				if (current_target = random_target) {
				my_building<-random_building;
				inside<-true;
				float dist<-50#m;
				list<road> roads_neigh <- (road at_distance dist);
					loop while: empty(roads_neigh) {
						dist <- dist + 20;
						roads_neigh <- (road at_distance dist);
					}
					road a_road <- roads_neigh[rnd_choice(roads_neigh collect each.shape.perimeter)];
					my_car.location <- any_location_in(a_road);
				
				} else {
					in_car <- true;
					current_target <- random_target;
				}
			}
		}
	}


	action going_upstairs {

		current_stair <- my_building.nb_stairs;
	}
	
	

	action inquiring_information {
	
	}
	



	action protect_my_car {
		inside<-false;
		current_stair <- 0;	
		speed <- my_speed();
		if (final_target = nil) {
			road a_road <- safe_roads[rnd_choice(safe_roads collect (1.0/(1 + each.location distance_to my_car.location)))];
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
		float t; if benchmark {t <- machine_time;}
		do protect_properties;
		if benchmark {ask world {do add_data_benchmark("people - protect_my_properties", machine_time - t);}}
	}


	action moving {
		inside<-false;
		list<road> rd <- not_usable_roads where ((each distance_to self) < flooded_road_percep_distance) ;
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
		
		}
		if (current_graph = nil) {
			
			current_graph <- road_network_custom[known_blocked_roads];
		}
		do goto target: current_target on: current_graph = nil ? first(road_network_custom.values) :  current_graph move_weights: current_weights ;
		if (location = current_target) {
			current_graph <- nil;
		}
			
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
//***************************  PEOPLE BDI   **********************************************************************
//***********************************************************************************************************
species peoplebdi skills: [moving] control:  simple_bdi {
	building my_building;
	car my_car;
	bool have_car;
	int Age;
	string Sexe;
	string iris;
	string Couple;
	string CSP;
	
	int current_stair;
	bool know_rules;
	point my_location;
	bool in_car <- false;
	bool inside<-true;
	bool injuried_inside<-false;
	bool injuried_outside<-false;
	int friends_to_inform_to_select;
	list<peoplebdi> friends_to_inform;
	
	float satisfaction<-0.5; //0: not satisfy at all, 1: very satisfied
	
	
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
	float strength_drain_off <- rnd(0.5);
	float strength_evacuate <- rnd(0.5);
	float strength_inform <- rnd(-0.5, 0.5);
	float strength_upstairs <- rnd(1.0);
	float strength_inquire <- rnd(-0.5, 0.5);
	float strength_protect_car <- rnd(1.0);
	float strength_protect_properties <- rnd(1.0);
	float strength_protect_turn_off <- rnd(1.0);
	float strength_protect_weather_strip <- rnd(1.0);
	float strength_outside<-rnd(1.0) ;
	float strength_do_nothing <- 0.25 ;
	
	float danger_inside <- 0.0; //between 0 and 1 (1 danger of imeediate death)
	float danger_outside <- 0.0; //between 0 and 1 (1 danger of imeediate death)
	float proba_evacuation<-0.0;
	float obedience_init;
	point current_target;
	point final_target;
	point random_target;
	building random_building;
	rgb my_color <- #mediumvioletred;
	bool use_emotions_architecture <- true; //we set this built-in variable to true to use the emotional process
	bool use_personality <- true;
	bool return_home <- false;
	
	list<int> known_blocked_roads;
	
	graph current_graph;
	
	float outside_test_period <- rnd(15,30) #mn;
	cell my_current_cell;
	
	float water_level <- 0.0;
	
	float prev_water_inside <- 0.0;
	float prev_water_outside <- 0.0;
	
	
	float max_danger_inside<-0.0;
	float max_danger_outside<-0.0;
		

	//***************************  perception ********************************
	reflex my_perception {
		if mode_flood {
		float t; if benchmark {t <- machine_time;}
		fear_level <- has_emotion(fear) ? get_emotion(fear).intensity : 0.0;
		strength_do_nothing <-  0.25 - fear_level;
		obedience <- obedience_init - 0.2 * abs(0.5 - fear_level);
		if (has_desire(outside)) {
			mental_state out <- get_desire(outside);
			out <- out  set_strength (strength_outside - fear_level);
		}
		bool water_cell_neighbour <- false;
		bool water_cell <- false;
		bool water_building <- false;
		do remove_belief(house_flooded);
		do remove_belief(water_at_my_door);
		danger_inside<-0.0;
		danger_outside<-0.0;
		if inside {
			float whp <- water_height_perception;
			water_cell <- my_building.water_cell;
			
			water_cell_neighbour <- my_building.neighbour_water;
			water_level <- my_building.water_height;
			do increase_life_at_stake(prev_water_inside);
			
			prev_water_inside <- my_building.water_height ;
			if my_building.water_height >= water_height_problem {
				water_building <- true;
				do add_belief(vulnerable_properties);	 
				do add_belief(vulnerable_building);		
			}
			
			
			if water_building {	
				do add_belief(house_flooded);
				do remove_desire(outside);
			}
			if water_cell {	
				do add_belief(water_at_my_door);
				do add_belief(water_is_here);
				do remove_desire(outside);
			} else if water_cell_neighbour {
				do add_belief(water_is_here);
				do remove_desire(outside);
			}
			
		} else if (my_current_cell != nil) {
			water_level <- my_current_cell.water_height;
			do increase_life_at_stake(prev_water_outside);
			prev_water_outside <- my_current_cell.water_height;
		
			
			if (my_current_cell.water_height > water_height_perception) {do add_belief(water_is_here);}
		
		} 
		if benchmark {ask world {do add_data_benchmark("people - perception", machine_time - t);}}
	}
	
	
	do test_proba; //when: (time mod 10#mn) = 0
	do agenda; // when:(time mod outside_test_period) = 0
	do fear_contagion; // when: (time mod 30#mn) = 0
	
	}
	
	action increase_life_at_stake(float prev_water_level) {
		if (water_level >= (prev_water_level + 1 #cm)) {
			do add_uncertainty(life_at_stake, coeff_life_at_stake_water_increase *(water_level -prev_water_level) );
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
						if not (self in injured_how.keys) {
							injuried_inside<-true;
							injuried_people <- injuried_people+1;
							injured_how[self] <- current_plan;
						}
					}
				}
				
		}else if my_current_cell != nil{
			float wh<-my_current_cell.water_height; 
			if in_car {danger_outside<-max([danger_outside,max([0,min([1.0, (wh-water_height_danger_car)/water_height_danger_car])])]);	}
			else {danger_outside<-max([danger_outside,max([0,min([1.0, (wh-water_height_danger_pied)/water_height_danger_pied])])]);}
			if danger_outside >0 {
				max_danger_outside <- max(max_danger_outside, danger_outside);
						
				if not (self in injured_how.keys) {
					injuried_outside<-true;
					injuried_people <- injuried_people+1;
					injured_how[self] <- current_plan;
					//write name + " " + current_plan;
				}
				
			}
		}
	}
	
	action test_proba  {
		float t; if benchmark {t <- machine_time;}
		if flip(max_danger_outside) or flip(max_danger_inside) {
			do to_die;
		}
		max_danger_inside <- 0.0;
		max_danger_outside <- 0.0;
		
		if benchmark {ask world {do add_data_benchmark("people - test_proba", machine_time - t);}}
	}
	
		
	action agenda{
		float t; if benchmark {t <- machine_time;}
		if flip(0.3) {do add_belief(need_to_go_outside);}
		
		if benchmark {ask world {do add_data_benchmark("people - test_proba", machine_time - t);}}
	}
	
	
	
	action to_die {
		if (inside) {
			dead_people <- dead_people + 1;
		} else {
			dead_people <- dead_people + 1;
		
		}
			if not (self in injured_how.keys) {
			if (injuried_outside) {
				injuried_people <- injuried_people - 1;
			}
			if (injuried_inside) {
				injuried_people <- injuried_people - 1;
			}	
			remove key: self from:injured_how; 
		}
		dead_how[self] <- current_plan;
		ask friends_to_inform {
			friends_to_inform >> self;
		}
		do die;
	}
	

	
		//if the agent perceives other people agents in their neighborhood that have fear, it can be contaminate by this emotion
	action fear_contagion {
		float t; if benchmark {t <- machine_time;}
		ask people at_distance fear_contagion_distance  {
			emotional_contagion emotion_detected:fear ;
		}
		if benchmark {ask world {do add_data_benchmark("people - fear_contagion", machine_time - t);}}
	}
	
	bool bool_house_flooded <- false update: has_belief(house_flooded);
	bool bool_water_is_here <- false update: has_belief(water_is_here);
	bool bool_water_is_coming <- false update: has_belief(water_is_coming);
	bool bool_water_at_my_door <- false update: has_belief(water_at_my_door);
	
	bool bool_property_protected <- false update: has_belief(property_protected);
	bool bool_property_impermeable <- false update: has_belief(property_impermeable);
	
	bool bool_vulnerable_properties <- false update: has_belief(vulnerable_properties);
	bool bool_vulnerable_building <- false update: has_belief(vulnerable_building);
	bool bool_vulnerable_car <- false update: has_belief(vulnerable_car);
	
	//***************************  REGLES BDI ********************************************************
	//	
	
   law follow_rule_inquire when: know_rules and not bool_water_is_coming new_obligation: inquire strength: 3.0 threshold: 0.6;
   law follow_rule_upstaire belief: crisis_event new_obligation: upstairs when:know_rules and (current_stair < my_building.nb_stairs) and house_flooded strength: 2.0  threshold: 0.65;
   law follow_rule_protect when: know_rules and bool_water_is_coming and not bool_water_at_my_door and not bool_property_protected new_obligation: protect_properties  strength: 2.0  threshold: 0.65;
   law follow_rule_strip when: know_rules and bool_water_is_coming and not bool_house_flooded and  not bool_property_impermeable new_obligation: weather_strip  strength: 2.0  threshold: 0.65;
   law follow_rule_wait belief: crisis_event new_obligation: wait when:know_rules strength: 1.0  threshold: 0.675;
   
   	rule when: not bool_water_at_my_door and not bool_house_flooded and has_belief(need_to_go_outside) new_desire: outside strength:strength_outside - fear_level;
	rule when: strength_inquire > 0 and not bool_water_is_coming new_desire: inquire strength: strength_inquire;
	
	rule when: strength_inform > 0 belief: water_is_coming new_desire: inform strength: strength_inform;
	
	rule when: bool_house_flooded and not bool_water_at_my_door new_desire: drain_off strength: strength_drain_off;
	rule when: have_car and bool_vulnerable_car and (bool_water_is_here or bool_water_is_coming or bool_house_flooded or bool_water_at_my_door) new_desire: protect_car strength: strength_protect_car;
	rule when: (bool_vulnerable_properties or bool_water_is_here or bool_water_is_coming) and not bool_property_protected new_desire: protect_properties strength: strength_protect_properties;
	rule when: (bool_water_at_my_door or bool_house_flooded or bool_water_is_coming) and has_belief(energy_is_on) and has_belief(energy_is_dangerous) new_desire: turn_off strength: strength_protect_turn_off;
	rule when: (bool_vulnerable_building or bool_water_is_here or bool_water_is_coming) and not bool_property_impermeable new_desire: weather_strip strength: strength_protect_weather_strip;
	
	
	rule belief: evacuation_is_possible when: fear_level > threshold_fear_intensity new_desire: evacuate strength: strength_evacuate;
	rule when: (bool_water_at_my_door or bool_house_flooded) and (current_stair < my_building.nb_stairs) and  fear_level > threshold_fear_intensity  new_desire: upstairs strength: strength_upstairs;
	
	rule belief: house_flooded new_uncertainty: life_at_stake strength: life_at_stake_house_flooded;  
	rule belief: water_at_my_door new_uncertainty: life_at_stake  strength: life_at_stake_water_at_my_door;  
	rule belief: house_flooded new_uncertainty: life_at_stake strength: life_at_stake_house_flooded;  
	
	//***************************  NORMS  ********************************************************
	norm instruction_wait obligation: wait{
		float t; if benchmark {t <- machine_time;}
		 do remove_intention(wait, true); 
		if benchmark {ask world {do add_data_benchmark("people - norm instruction_wait", machine_time - t);}}
		
	}
	norm behaviour_inquire obligation: inquire {
		float t; if benchmark {t <- machine_time;}
		do inquiring_information;
		do remove_intention(inquire, true);
		if benchmark {ask world {do add_data_benchmark("people - norm behaviour_inquire", machine_time - t);}}
	}
	
	norm behaviour_upstairs obligation: upstairs {
		float t; if benchmark {t <- machine_time;}
		do going_upstairs;
		do remove_intention(upstairs, true);
		if benchmark {ask world {do add_data_benchmark("people - norm behaviour_upstairs", machine_time - t);}}
	}
	
	
	norm protect_properties obligation: protect_properties {
		float t; if benchmark {t <- machine_time;}
		do protect_properties;
		do remove_intention(protect_properties, true);
		if benchmark {ask world {do add_data_benchmark("people - norm protect_properties", machine_time - t);}}
	}
	
	norm weather_strip_house obligation: weather_strip {
		float t; if benchmark {t <- machine_time;}
		do weather_strip_house;
		do remove_intention(weather_strip, true);
		if benchmark {ask world {do add_data_benchmark("people - norm weather_strip_house", machine_time - t);}}
	}
	 
	
		//***************************  PLANS  ********************************************************
	
	
	plan do_nothing intention: do_nothing {
		float t; if benchmark {t <- machine_time;}
	
		do remove_intention(do_nothing, true);
		do add_desire(do_nothing, strength_do_nothing);
		if benchmark {ask world {do add_data_benchmark("people - test_proba", machine_time - t);}}
		
	}

	plan drain_off_water intention: drain_off {
		float t; if benchmark {t <- machine_time;}
	
		my_building.water_height <- max([0, my_building.water_height - 0.01 #m3 / #mn / my_building.shape.area * step]);
		do remove_intention(drain_off, true);
		nb_drain_off <- nb_drain_off+ 1;
		nb_waiting <- nb_waiting - 1;
		current_stair <- 0;
		
		if benchmark {ask world {do add_data_benchmark("people - drain_off_water", machine_time - t);}}
	}


	plan evacuate intention: evacuate {
		float t; if benchmark {t <- machine_time;}
		
		current_stair<-0;
		
		inside<-false;
		nb_evacuate <- nb_evacuate+ 1;
		nb_waiting <- nb_waiting - 1;
		my_color <- #gold;
		speed <- my_speed();
		if (final_target = nil) {
			final_target <- (escape_cells with_min_of (each.location distance_to location)).location;
			if (have_car) {
				current_target <- my_car.location;
			} else {
				current_target <- final_target;
		//		write ("j'ai atteint ma voiture");
			}

		} else {
			do moving;
			if( in_car) {
				my_car.location <- location;
			}
			if (current_target = location) {
				if (current_target = final_target) {
					
					leaving_people <- leaving_people + 1;
					if (in_car) {ask my_car {do die;}}
					do die;
				} else {
					in_car <- true;
					current_target <- final_target;
				}

			}

		}
		if benchmark {ask world {do add_data_benchmark("people - evacuate", machine_time - t);}}
	}


	plan give_information intention: inform  when: not empty(friends_to_inform){
		float t; if benchmark {t <- machine_time;}
		
		nb_inform <- nb_inform+ 1;
		nb_waiting <- nb_waiting - 1;
		peoplebdi people_to_inform <- friends_to_inform with_max_of (get_social_link(new_social_link(each)).liking + get_social_link(new_social_link(each)).solidarity);
		ask one_of(friends_to_inform) {
			do add_belief(water_is_coming);
			emotional_contagion emotion_detected:fear ;
			myself.friends_to_inform >> self;
			friends_to_inform >> myself;
			strength_inform <-  empty(friends_to_inform) ? -1.0 : strength_inform;
	
		}
		strength_inform <-  empty(friends_to_inform) ?-1.0: (strength_inform - strength_information_decrement);
		do remove_intention(inform, true);
		
		if benchmark {ask world {do add_data_benchmark("people - give_information", machine_time - t);}}
	}


	plan go_outside intention: outside {
		float t; if benchmark {t <- machine_time;}
		current_stair<-0;		
		nb_outside <- nb_outside+ 1;
		nb_waiting <- nb_waiting - 1;
		inside<-false;
		my_color <- #pink;
		speed <- my_speed();
		if (random_target = nil) {
			random_building<-one_of (building);
			random_target <- (random_building.location);
			if (have_car) {
				current_target <- my_car.location;
			} else {
				current_target <- random_target;
			}

		} else {
			do moving;
			if( in_car) {
				my_car.location <- location;
			}
			if (current_target = location) {
				if (current_target = random_target) {
		//			write "j'y suis";
				my_building<-random_building;
				inside<-true;
				do remove_belief(need_to_go_outside);
				do remove_intention(outside, true);
				float dist<-50#m;
				list<road> roads_neigh <- (road at_distance dist);
					loop while: empty(roads_neigh) {
						dist <- dist + 20;
						roads_neigh <- (road at_distance dist);
					}
					road a_road <- roads_neigh[rnd_choice(roads_neigh collect each.shape.perimeter)];
					my_car.location <- any_location_in(a_road);
				
				} else {
					in_car <- true;
					current_target <- random_target;
				}

			}

		}
		
		
		if benchmark {ask world {do add_data_benchmark("people - go_outside", machine_time - t);}}
	}


	action going_upstairs {
		nb_upstairs <- nb_upstairs+ 1;
		nb_waiting <- nb_waiting - 1;
		current_stair <- my_building.nb_stairs;
	}
	
	
	plan go_upstairs intention: upstairs {
		float t; if benchmark {t <- machine_time;}
		do going_upstairs;
		do remove_intention(upstairs, true);
		if benchmark {ask world {do add_data_benchmark("people - go_upstairs", machine_time - t);}}
	}

	action inquiring_information {
		nb_inquire <- nb_inquire+ 1;
		nb_waiting <- nb_waiting - 1;
		do add_belief(water_is_coming);	
	}
	
	plan inquire_information intention: inquire {
		float t; if benchmark {t <- machine_time;}
		do inquiring_information;
		do remove_intention(inquire, true); 	
		if benchmark {ask world {do add_data_benchmark("people - inquire_information", machine_time - t);}}
	}


	plan protect_my_car intention: protect_car {
		float t; if benchmark {t <- machine_time;}
		inside<-false;
		current_stair <- 0;
		nb_protect_car <- nb_protect_car+ 1;
		nb_waiting <- nb_waiting - 1;	
		speed <- my_speed();
		if (final_target = nil) {
		//	write length(safe_roads);
			road a_road <- safe_roads[rnd_choice(safe_roads collect (1.0/(1 + each.location distance_to my_car.location)))];
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
						do remove_belief(vulnerable_car); 
						do remove_intention(protect_car, true);
						return_home <- false;
					} else {
						in_car <- true;
						current_target <- final_target;
					}
					
				}
				

			}

		}
		
		if benchmark {ask world {do add_data_benchmark("people - protect_my_car", machine_time - t);}}
	}


	plan protect_my_properties intention: protect_properties {
		float t; if benchmark {t <- machine_time;}
		do protect_properties;
		do remove_intention(protect_properties, true); 	
		if benchmark {ask world {do add_data_benchmark("people - protect_my_properties", machine_time - t);}}
	}


	action moving {
		inside<-false;
		list<road> rd <- not_usable_roads where ((each distance_to self) < flooded_road_percep_distance) ;
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
		
		}
		if (current_graph = nil) {
			
			current_graph <- road_network_custom[known_blocked_roads];
		}
		do goto target: current_target on: current_graph = nil ? first(road_network_custom.values) :  current_graph move_weights: current_weights ;
		if (location = current_target) {
			current_graph <- nil;
		}
			
	}

	action protect_properties {
		nb_protect_properties <- nb_protect_properties+ 1;
		current_stair<-0;
		nb_waiting <- nb_waiting - 1;
		my_building.vulnerability <- my_building.vulnerability - (0.2 * step / 1 #h);
		if (my_building.vulnerability <= my_building.min_vulnerability) {
			do add_belief(property_protected);
		}
}


	plan turn_off_nrj intention: turn_off {
		float t; if benchmark {t <- machine_time;}
		nb_turn_off <- nb_turn_off+ 1;
		current_stair<-0;
		nb_waiting <- nb_waiting - 1;
		my_building.nrj_on <- false;
		do remove_belief(energy_is_on);
		do remove_intention(turn_off, true);
		if benchmark {ask world {do add_data_benchmark("people - turn_off_nrj", machine_time - t);}}
	}

	plan weather_strip_house intention: weather_strip {
		float t; if benchmark {t <- machine_time;}
		do weather_strip_house;
		do remove_intention(weather_strip, true); 
		if benchmark {ask world {do add_data_benchmark("people - weather_strip_house", machine_time - t);}}	
	}
	
	
	action weather_strip_house {
		nb_weather_strip <- nb_weather_strip+ 1;
		current_stair<-0;
		nb_waiting <- nb_waiting - 1;
		my_building.impermeability <- my_building.impermeability + (0.05*step / 1 #h);
		if (my_building.impermeability >= my_building.max_impermeability) {
			do add_belief(property_impermeable);
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
	
	
	
	float K<-25.0; //coefficient de Strickler
	float slope;
	float water_abs<-0.0;
	float water_abs_max<-0.01;
	map<cell, float> delta_alt_neigh;
	map<cell, float> slope_neigh;
	list<cell> flow_cells;
	float slope_tot;
	float wac;
	float wpc;
	float rh;
	float V;
	float dp;
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
	//water_volume<-water_volume*(1-permeability);
	water_abs<-water_abs+water_volume;
	if water_abs>water_abs_max {permeability<-0.0;}
	//permeability<-max([0,permeability-(water_abs_max-water_volume)/water_abs_max]);
	}
	
	
	
	
	
	action compute_water_altitude {
			if is_river {water_river_height<-min([water_volume/(sqrt(cell_area)*river_broad),river_depth]);}
			else {water_river_height<-0.0;}
			water_height<-(max([0,water_volume-(water_river_height*river_broad*sqrt(cell_area))])/cell_area);
			water_altitude<-altitude -river_depth+water_river_height+ water_height;
	}
		
		

		
	action verify_river_full {
		is_river_full<-false;
		if !is_river {is_river_full<-true;}
		else {
			if water_volume>=(my_rivers max_of(each.river_depth)*my_rivers max_of(each.river_broad)*sqrt(cell_area)) {
				is_river_full<-true;
			}
		}
	}

	action compute_slope {
		slope_tot<-0.0;
			slope<-0.0;
			delta_alt_neigh <- neighbors as_map (each::max([0,(water_altitude-each.water_altitude)]));
		//	slope_neigh <- neighbors as_map (each::max([0,(water_altitude-each.water_altitude)/sqrt(cell_area)]));
			slope_neigh <- neighbors as_map (each::max([0,(water_altitude-(each.water_altitude-each.river_depth))/sqrt(cell_area)]));
			
			
			loop det over:slope_neigh {
				slope_tot<-slope_tot+det;
				slope<-max([det, slope]);
			}
		
			
		/*	ask neighbors {
				self.delta_alt_neigh[myself] <- self.water_altitude-myself.water_altitude;
				self.slope_neigh[myself] <- max([0,delta_alt_neigh[myself]/sqrt(cell_area)]);
				self.slope_tot<-self.slope_tot+slope_neigh[myself];
				self.slope<-max([slope_neigh[myself], self.slope]);
			}	
			 */
		//	write delta_alt_neigh;
		}


	//Action to flow the water 
	action flow {
		is_flowed<-false;
		//if the height of the water is higher than 1cm then, it can flow among the neighbour cells
		if (water_height>1#cm or water_river_height>1#cm ) {
		do compute_water_altitude;	
		do verify_river_full;
		//We get all the cells already done
		

			list<cell> neighbour_cells_al <- neighbors where (each.already);

			//If there are cells already done then we continue         
			do compute_slope;
			if (!empty(neighbour_cells_al)) {
				
				//water area (coupe)
				wac<-water_river_height*river_broad+sqrt(cell_area)*water_height;
				
				//water perimeter (coupe)
				wpc<-2*(water_river_height+river_broad+sqrt(cell_area)+water_height); 
				
				//hydraulic diameter
				rh<-wac/(2*wpc);
				
				//flow velocity
				V<-min([max_speed,max([0.1,rh^(2/3)*K*slope^(1/2)])]);	
				
				Vmax<-max([V,Vmax]);			
				dp<-V*step/repeat_time; //distance parcourue en 1 step
				prop<-min([1,max([0.1,(dp-sqrt(cell_area))/sqrt(cell_area)])]); //proportion eau transmise
				volume_distrib<-max([0,water_volume*prop]);
				
				
				//water_altitude<-altitude -river_depth+water_river_height+ water_height;
				
			/* 	if is_canal_origin {
							water_volume <- max([0,water_volume - volume_max*one_of(canal).coeff_enter_canal]);
							do compute_water_altitude;
							}*/
					
				
				//We compute the height of the neighbours cells according to their altitude, water_height and obstacle_height
					ask neighbour_cells_al {do compute_water_altitude;	}
																					
					//The water of the cells will flow to the neighbour cells which have a height less than the height of the actual cell
					
					ask neighbour_cells_al {
						may_flow_cell<-false;
						if myself.water_altitude > water_altitude {
							if is_river_full {
								if (myself.water_altitude > (altitude+dyke_height-river_depth)) {may_flow_cell<-true;	}	
							}
							if !is_river_full {
								if (myself.water_altitude > (altitude-river_depth)) {may_flow_cell<-true;	}	
							}

						}
					}
				//	flow_cells <- (neighbour_cells_al where ((self.water_altitude > each.water_altitude) and (self.water_altitude > (each.altitude+each.dyke_height-each.river_depth))));
					flow_cells <- (neighbour_cells_al where (each.may_flow_cell));					
				//If there are cells, we compute the water flowing
					if (!empty(flow_cells)) {			
						
						//volume_distrib<-volume_max*(nb_neighbors/8);
						//float slopetot<-0.0;
						//ask flow_cells {slopetot<-slopetot+max([0.05,myself.altitude-self.altitude]);}
						is_flowed<-true;
				//	float prop_flow;
					//prop_flow<-1/length(flow_cells);
					
					float slope_sum<-flow_cells sum_of(slope_neigh[each]);

						ask flow_cells {
						
							if slope_sum>0 {prop_flow<-myself.slope_neigh[self]/slope_sum;}
								else {prop_flow<-0.0;}
							volume_distrib_cell<-myself.volume_distrib*prop_flow;
							water_volume <- water_volume + volume_distrib_cell;
							do absorb_water;	
							do compute_water_altitude;
	
						} 
		/* 
						loop flow_cell over: shuffle(flow_cells) sort_by (each.altitude) {
							volume_distrib_cell<-volume_distrib*(max([0.05,self.slope_neigh(flow_cell)/slope_tot]));							
							flow_cell.water_volume <- flow_cell.water_volume + volume_distrib_cell;					
							ask flow_cell {do compute_water_altitude;}
						}*/
						
					
				 		
				 		water_volume <- water_volume - volume_distrib;
						do compute_water_altitude;
					
					}
			} 
 
 
 }

			

		already <- true;
		if is_sea {
			water_height <- 0.0;
		}

	}

	//Action to flow the water 
	action flow2 {
		is_flowed<-false;
		if (water_height>1#cm or water_river_height>1#cm ) {
		do compute_water_altitude;	
		do verify_river_full;
			int nb_neighbors<-length(neighbors);   
			list<cell> neighbour_cells_al <- neighbors where (each.already);
			list<cell> cell_to_flow;		
			V<-3#m/#s;
			dp<-V*step; //distance parcourue en 1 step
			//prop<-min([1,max([0.1,(dp-sqrt(cell_area))/sqrt(cell_area)])]); //proportion eau transmise
			prop<-1.0;
			volume_distrib<-max([0,water_volume*prop]);
			
			float w_a<-water_altitude;
			//add self to:cell_to_flow;
			ask neighbour_cells_al {
				do absorb_water;	
				do compute_water_altitude;
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
					float tot_den<-flow_cells sum_of (max([0,w_a-(each.altitude)]));
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
							prop_flow<-(w_a-altitude)/tot_den;
							volume_distrib_cell<-with_precision(myself.volume_distrib*prop_flow,4);
							water_volume <- water_volume + volume_distrib_cell;	
							do compute_water_altitude;
							
						} 
				 		water_volume <- water_volume - volume_distrib;
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


	//Action to flow the water 
	action flow3 {
		is_flowed<-false;
		if (water_height>0.5#cm or water_river_height>0.5#cm ) {
		do compute_water_altitude;	
		do verify_river_full;
			int nb_neighbors<-length(neighbors);
			list<cell> neighbour_cells_al <-  agents_at_distance(dp) of_species cell where (each.already);     
			do compute_slope;
				wac<-water_river_height*river_broad+sqrt(cell_area)*water_height;
				wpc<-2*(water_river_height+river_broad+sqrt(cell_area)+water_height); 
				rh<-wac/(2*wpc);
				V<-min([max_speed,max([0.1,rh^(2/3)*K*slope^(1/2)])]);	
				Vmax<-max([V,Vmax]);			
				dp<-V*step; //distance parcourue en 1 step
				volume_distrib<-water_volume;
				if (!empty(neighbour_cells_al)) {
					ask neighbour_cells_al {do compute_water_altitude;	}
					
						
					ask neighbour_cells_al {
						may_flow_cell<-false;
						if myself.water_altitude > water_altitude {
							if is_river_full {
								if (myself.water_altitude > (altitude+dyke_height-river_depth)) {may_flow_cell<-true;	}	
							}
							if !is_river_full {
								if (myself.water_altitude > (altitude-river_depth)) {may_flow_cell<-true;	}	
							}

						}
					}
				//	flow_cells <- (neighbour_cells_al where ((self.water_altitude > each.water_altitude) and (self.water_altitude > (each.altitude+each.dyke_height-each.river_depth))));
					flow_cells <- (neighbour_cells_al where (each.may_flow_cell));	
					if (!empty(flow_cells)) {			
						is_flowed<-true;
						float prop_flow;
						prop_flow<-1/length(flow_cells);
						float slope_sum<-flow_cells sum_of(slope_neigh[each]);
						ask flow_cells {
							volume_distrib_cell<-myself.volume_distrib*prop_flow;
							water_volume <- water_volume + volume_distrib_cell;	
							do absorb_water;	
							do compute_water_altitude;
						} 
				 		water_volume <- water_volume - volume_distrib;
						do compute_water_altitude;
					}
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
			
		if water_height>0#cm or water_river_height>0#cm {
		val_water <- max([0, min([200, int(200 * (1 - (water_height / 100#cm)))])]);
		color <- rgb([val_water, val_water, 255]);
		}
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
grid button width:2 height:3 
{
	int id <- int(self);
	rgb bord_col<-#black;
	aspect normal {
		draw rectangle(shape.width * 0.8,shape.height * 0.8).contour + (shape.height * 0.01) color: bord_col;
		draw image_file(images[id]) size:{shape.width * 0.5,shape.height * 0.5} ;
	}
}

//***********************************************************************************************************
//***************************  OUTPUT  **********************************************************************
//***********************************************************************************************************

experiment Benchmark type: gui autorun:true {
	action _init_ {
		create simulation with:(benchmark: true, scen:false, verbose:false);
	}
	
}

experiment "Simulation" type: gui {
	
	output {
		display map type: opengl background: #black draw_env: false {
			grid cell  triangulation:false refresh: true ;
			species cell  refresh: true aspect:map;
			species green_area;	
			species natura;
			species parking;
			species building;
			species road;
			species obstacle;
			species river;
			species people;
			species car;
			//species project;	
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
		
		/* 
		display charts refresh: every(10 #mn) {
			chart "Water level " size:{1.0, 1/4} {
				data "Water level" value: cell sum_of (each.water_height) color: #blue;
			}
			chart "number of aware people " size:{1.0, 1/4}  position: {0.0, 1/4}{
				data "number of people" value: length(people) color: #gray;
					
				data "number of people aware" value: people count each.bool_water_is_coming color: #blue;
				data "number of people with waree is here" value: people count each.bool_water_is_here color: #magenta;
				data "number of people with water_at_my_door" value: people count each.bool_water_at_my_door color: #pink;
				data "number of people with house_flooded" value: people count each.bool_house_flooded color: #violet;
				
				data "number of people with vulnerable car" value: people count each.bool_vulnerable_car color: #black;
				data "number of people with vulnerable property " value: people count (each.bool_vulnerable_properties and not each.bool_property_protected) color: #red;
				data "number of people with vulnerable building" value: people count (each.bool_vulnerable_building and not each.bool_property_impermeable) color: #orange;
			}
			
			chart "number of injured and death" size:{1.0, 1/4} position: {0.0, 2/4} {
				data "number of evacuated people" value: leaving_people color: #green;
				data "number of deads inside" value: dead_people color: #brown;
				data "number of deads outside" value: dead_people color: #red;
				
				data "number of injured people inside" value: injuried_people color: #yellow;
				data "number of injured people outside" value: injuried_people color: #orange;
				
			}
			
	
			chart "current plan" size:{1.0, 1/4} position: {0.0, 3/4} {
				data "nb of people waiting" value: nb_waiting color: #gray; 
				data "nb of people draininf off" value:nb_drain_off color: #blue; 
				data "nb of people evacuating" value:nb_evacuate color: #yellow; 
				data "nb of people informing others" value:nb_inform color: #magenta; 
				data "nb of people going outside" value:nb_outside color: #pink; 
				data "nb of people going upstair" value:nb_upstairs color: #violet; 
				data "nb of people searching information" value:nb_inquire color: #orange; 
				data "nb of people protecting car" value:nb_protect_car color: #red; 
				data "nb of people protecting property" value:nb_protect_properties color: #brown; 
				data "nb of people turn off electricity" value:nb_turn_off color: #cyan; 
				data "nb of people striping property" value:nb_weather_strip color: #lightgreen; 
				
				
			}
			
		}*/

	
	
	
	
	
	experiment Interation type: gui {
	output {
			layout horizontal([0.0::7285,1::2715]) tabs:true;
		display map type: opengl background: #black draw_env: false refresh:true{
			species cell  refresh: true aspect:map;
			species green_area;
			species natura;	
			species parking;
			species building;
			species road;
			species obstacle;
			species river;
			species pluvial_network;
			species people;
			species car;
		//	species project;
			event mouse_down action:cell_management;
			
		}
		//display the action buttons
		display action_buton background:#black name:"Tools panel"  	{
			species button aspect:normal ;
			event mouse_down action:activate_act;    
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
