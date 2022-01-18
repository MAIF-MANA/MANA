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

	file mnt_file <- grid_file("../results/grid4.asc");
	file my_data_flood_file <- csv_file("../includes/data_flood3.csv", ",");
	file my_data_rain_file <- csv_file("../includes/data_rain.csv", ",");
	shape_file res_buildings_shape_file <- shape_file("../la_vita_territoire/residential_building.shp");
	shape_file market_shape_file <- shape_file("../la_vita_territoire/market.shp");
	shape_file erp_shape_file <- shape_file("../la_vita_territoire/erp.shp");
	shape_file main_roads_shape_file <- shape_file("../la_vita_territoire/main_road.shp");
	shape_file roads_shape_file <- shape_file("../la_vita_territoire/city_roads.shp");
	shape_file highway_shape_file <- shape_file("../la_vita_territoire/highway.shp");
	shape_file waterways_shape_file <- shape_file("../la_vita_territoire/river.shp");
	shape_file green_shape_file <- shape_file("../la_vita_territoire/green_area.shp");
	shape_file sea_shape_file <- shape_file("../la_vita_territoire/sea.shp");
	shape_file bridge_shape_file <- shape_file("../la_vita_territoire/passage_pont.shp");
	shape_file ground_shape_file <- shape_file("../la_vita_territoire/riviere_enterree.shp");
	shape_file wall_shape_file <- shape_file("../la_vita_territoire/dikes_murets_classes.shp");
	shape_file rain_net_shape_file <- shape_file("../la_vita_territoire/pluvial_network.shp");
	shape_file parking_shape_file <- shape_file("../la_vita_territoire/parking.shp");
	shape_file plu_nat_shape_file <- shape_file("../la_vita_territoire/PLU_N.shp");
	shape_file plu_a_urb_shape_file <- shape_file("../la_vita_territoire/PLU_AU.shp");
	shape_file plu_agri_shape_file <- shape_file("../la_vita_territoire/PLU_A.shp");
	shape_file natura_shape_file <- shape_file("../la_vita_territoire/NATURA_2000.shp");
	
	
	//shape file actions
	shape_file bassin_shape_file <- shape_file("../la_vita_ak_actions/bassin_retention.shp");
	shape_file barrage_shape_file <- shape_file("../la_vita_ak_actions/barrage.shp");
	shape_file extension_nat_shape_file <- shape_file("../la_vita_ak_actions/extention_PLU_N.shp");
	shape_file noue_shape_file <- shape_file("../la_vita_ak_actions/noues_routes.shp");
	shape_file new_green_file  <- shape_file("../la_vita_ak_actions/new_green_area.shp");
	shape_file densification  <- shape_file("../la_vita_ak_actions/densification_urba_logmts.shp");
	shape_file new_rouZAC<- shape_file("../la_vita_ak_actions/extension_ZAC_routes.shp");
	shape_file new_nouZAC<- shape_file("../la_vita_ak_actions/extension_ZAC_noues_routes.shp");
	shape_file new_pluZAC<- shape_file("../la_vita_ak_actions/extension_ZAC_pluvial.shp");
	shape_file new_logZAC<- shape_file("../la_vita_ak_actions/extension_ZAC_bat.shp");	
	shape_file new_rou1<- shape_file("../la_vita_ak_actions/nouv_quartier_1_routes.shp");
	shape_file new_nou1<- shape_file("../la_vita_ak_actions/nouv_quartier_1_noues_routes.shp");
	shape_file new_plu1<- shape_file("../la_vita_ak_actions/nouv_quartier_1_pluvial.shp");
	shape_file new_par1<- shape_file("../la_vita_ak_actions/nouv_quartier_1_parking.shp");
	shape_file new_log1<- shape_file("../la_vita_ak_actions/nouv_quartier_1_logmts.shp");
	shape_file new_rou2<- shape_file("../la_vita_ak_actions/nouv_quartier_2_routes.shp");
	shape_file new_nou2<- shape_file("../la_vita_ak_actions/nouv_quartier_2_noues_routes.shp");
	shape_file new_plu2<- shape_file("../la_vita_ak_actions/nouv_quartier_2_pluvial.shp");
	shape_file new_par2<- shape_file("../la_vita_ak_actions/nouv_quartier_2_parking.shp");
	shape_file new_log2<- shape_file("../la_vita_ak_actions/nouv_quartier_2_logmts.shp");
	shape_file new_rou3<- shape_file("../la_vita_ak_actions/nouv_quartier_3_routes.shp");
	shape_file new_nou3<- shape_file("../la_vita_ak_actions/nouv_quartier_3_noues_routes.shp");
	shape_file new_plu3<- shape_file("../la_vita_ak_actions/nouv_quartier_3_pluvial.shp");
	shape_file new_par3<- shape_file("../la_vita_ak_actions/nouv_quartier_3_parking.shp");
	shape_file new_log3<- shape_file("../la_vita_ak_actions/nouv_quartier_3_logmts.shp");
	shape_file new_erp  <- shape_file("../la_vita_ak_actions/nouveaux_erp.shp");
	shape_file new_com  <- shape_file("../la_vita_ak_actions/nouveaux_com_entrep_ville.shp");
	
	int die_inside<-0;
	int die_in_car<-0;
	int die_outside<-0;
	int injuried_inside<-0;
	int injuried_in_car<-0;
	int injuried_outside<-0;
	
	date starting_date <- date([2022,1,2,14,0,0]);
	date time_flo;
	
	//shape_file population_shape_file <- shape_file("../includes/city_environment/population.shp");
	geometry shape <- envelope(mnt_file);
	
	bool code_test_end<-false;
	bool mode_test<-true;
	int nb_turn_test<-1;
	int nb_turn<-1;
	
	map<list<int>,	graph> road_network_custom;
	map<road, float> current_weights;
	graph road_network_simple;
	
	geometry rivers;
	river river_origin;
	river river_ending;
	int increment;
	matrix data_flood;
	matrix data_rain; 
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
	bool first_management_turn<-true;	

	float river_broad_maint <- 1 #m;
	float river_depth_maint<- 1 #m;
	float river_broad_normal<- 1#m;
	float river_depth_normal<-1#m;
	
	float cost_proj_tot<-0.0;

 	int level_ent_green<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
	int level_ent_dyke<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
 	int level_ent_pluvial<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
	int level_ent_nou<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
	int level_ent_riv<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
	

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
	
	int flo_str<-1; 	//0: petite à 4 : très fort 
	
	list<int> scen_flo<-[7,6,1,5];
	int incr_flo<-0;
	
	bool scen<-false;      //active ou desactive l'écran de selection des scnéario
	bool creator_mode<-true;
	bool kill_people<-false;
	
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

float flooded_building_erp;
float routes_inondees;

float flooded_building_prive;
float flooded_car;
float bien_endommage;

list<int> dead_injuried_peoples;

list<float> flooded_building_erps;
list<float> routes_inondeess;
list<float> flooded_building_prives;
list<float> bien_endommages;
list<float> flooded_cars;



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
float budget_espace_public<-0.0;
float budget_env<-0.0;
float budget_espace_public_moy<-0.0;
float budget_env_moy<-0.0;
float nb_res_init;
float nb_park_init;
int nb_erp_init;

//***************************  PREDICAT and EMOTIONS  ********************************************************

	
	list<road> not_usable_roads update: [];
	
	bool parallel_computation <- false;
	
	
	//Variables linked to benchmark
	map<string,float> time_taken_main;
	map<string,float> time_taken_sub;
	float display_every <- 5.0 * time_step;
	float init_time <- machine_time;
	

	
	
	
	
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
		nb_res_init<-building where (each.category=0) sum_of(each.shape.area*(1+each.nb_stairs));
		nb_erp_init<-length(building where (each.category=2));
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
		nb_park_init<-green_area sum_of(each.shape.area);
		do create_people;		
		
//0	Bassin arboré de rétention / infiltration
//1	Barrage écrêteur
//2	Extension zone N du PLU
//3	Création de fossés et noues (voirie)
//4	Aménager parcs et espaces verts
//5	Réparation biens publics
//6	Entretien parcs et espaces verts
//7	Réparation et entretien ouvrages de protection
//8	Réparation et entretien du pluvial
//9	Entretien noues et fossés
//10	Entretien cours d’eau
//11	Protections individuelles amovibles (logements)
//12	Murets de protection
//13	Achat biens confort / consommation
//14	Modifier PLU
//15	Délocaliser
//16	Protections individuelles (com et entrep.)
//17	Extension de la ZAC
//18	Construction commerces et entreprises en ville
//19	Réparation bâtiments com et entrep
//20	Réparation logements
//21	Densifier l'urbanisation
//22	Construction nouveau quartier 1
//23	Construction nouveau quartier 2
//24	Construction nouveau quartier 3
//25	Végétaliser toitures ZAC
//26	Végétaliser toitures (logements)
//27	Revêtements de sol perméables
//28	Puits infiltration
//29	Jardins de pluie
//30	Construction nouveau ERP

	//			ask project where (each.type=1 and each.Niveau_act=3) {do implement_project;}
	//		ask project where (each.type=0 and each.Niveau_act=2) {do implement_project;}
	//			ask project where (each.type=0 and each.Niveau_act=1) {do implement_project;}
 
		if kill_people {ask people 
			{
				ask my_car{do die;}				
				do die;
			}
		}
	}
	
	
		action create_project {
		create project from: bassin_shape_file {
			type<-0;
			shape<-scaled_by(shape,0.98); //juste pour réduire un peu la taille pour que ça reste dans le périmètre fixé sans déborder sur la route
			depth<-2#m;
			volume<-depth*shape.area*0.8;
		}
		
		create project from: barrage_shape_file	{
			type<-1;
			Niveau_act<-1;
		}
		
			create project from: barrage_shape_file	{
			type<-1;
			Niveau_act<-2;
		}
		
			create project from: barrage_shape_file	{
			type<-1;
			Niveau_act<-3;
		}
		
		
		create project from: extension_nat_shape_file	{
			type<-2;
		}
		
			create project from: noue_shape_file {
			type<-3;
		}
		
			create project from: new_green_file 	{
			type<-4;
		}
		
		create project 	{
			type<-5;
			Niveau_act<-1;
		}
		create project 	{
			type<-5;
			Niveau_act<-2;
		}
		create project 	{
			type<-5;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-6;
			Niveau_act<-1;
		}
		create project 	{
			type<-6;
			Niveau_act<-2;
		}
		create project 	{
			type<-6;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-7;
			Niveau_act<-1;
		}
		create project 	{
			type<-7;
			Niveau_act<-2;
		}
		create project 	{
			type<-7;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-8;
			Niveau_act<-1;
		}
		create project 	{
			type<-8;
			Niveau_act<-2;
		}
		create project 	{
			type<-8;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-9;
			Niveau_act<-1;
		}
		create project 	{
			type<-9;
			Niveau_act<-2;
		}
		create project 	{
			type<-9;
			Niveau_act<-3;
		}	
				
		create project 	{
			type<-10;
			Niveau_act<-1;
		}
		create project 	{
			type<-10;
			Niveau_act<-2;
		}
		create project 	{
			type<-10;
			Niveau_act<-3;
		}	
			
		create project 	{
			type<-11;
			Niveau_act<-1;
		}
		create project 	{
			type<-11;
			Niveau_act<-2;
		}
		create project 	{
			type<-11;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-12;
			Niveau_act<-1;
		}
		create project 	{
			type<-12;
			Niveau_act<-2;
		}
		create project 	{
			type<-12;
			Niveau_act<-3;
		}	
		
		
		create project 	{
			type<-13;
			Niveau_act<-1;
		}
		create project 	{
			type<-13;
			Niveau_act<-2;
		}
		create project 	{
			type<-13;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-14;
			Niveau_act<-1;
		}
		create project 	{
			type<-14;
			Niveau_act<-2;
		}
		create project 	{
			type<-14;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-15;
			Niveau_act<-1;
		}
		create project 	{
			type<-15;
			Niveau_act<-2;
		}
		create project 	{
			type<-15;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-16;
			Niveau_act<-1;
		}
		create project 	{
			type<-16;
			Niveau_act<-2;
		}
		create project 	{
			type<-16;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-17;
			Niveau_act<-1;
		}
		create project 	{
			type<-17;
			Niveau_act<-2;
		}
		create project 	{
			type<-17;
			Niveau_act<-3;
		}	
		
		create project from:new_com 	{
			type<-18;
			Niveau_act<-1;
		}
		create project from:new_com 	{
			type<-18;
			Niveau_act<-2;
		}
		create project from:new_com 	{
			type<-18;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-19;
			Niveau_act<-1;
		}
		create project 	{
			type<-19;
			Niveau_act<-2;
		}
		create project 	{
			type<-19;
			Niveau_act<-3;
		}	
		
		create project 	{
			type<-20;
			Niveau_act<-1;
		}
		create project 	{
			type<-20;
			Niveau_act<-2;
		}
		create project 	{
			type<-20;
			Niveau_act<-3;
		}	
		
		
			create project from: densification {
				type<-21;
			}
			
		create project 	{
			type<-22;
			Niveau_act<-1;
		}
		create project 	{
			type<-22;
			Niveau_act<-2;
		}
		create project 	{
			type<-22;
			Niveau_act<-3;
		}

		create project 	{
			type<-23;
			Niveau_act<-1;
		}
		create project 	{
			type<-23;
			Niveau_act<-2;
		}
		create project 	{
			type<-23;
			Niveau_act<-3;
		}	
			
		create project 	{
			type<-24;
			Niveau_act<-1;
		}
		create project 	{
			type<-24;
			Niveau_act<-2;
		}
		create project 	{
			type<-24;
			Niveau_act<-3;
		}	
				
		create project 	{
			type<-25;
			Niveau_act<-1;
		}
		create project 	{
			type<-25;
			Niveau_act<-2;
		}
		create project 	{
			type<-25;
			Niveau_act<-3;
		}
		
		create project 	{
			type<-26;
			Niveau_act<-1;
		}
		create project 	{
			type<-26;
			Niveau_act<-2;
		}
		create project 	{
			type<-26;
			Niveau_act<-3;
		}
		
		create project 	{
			type<-27;
			Niveau_act<-1;
		}
		create project 	{
			type<-27;
			Niveau_act<-2;
		}
		create project 	{
			type<-27;
			Niveau_act<-3;
		}
		
		create project 	{
			type<-28;
			Niveau_act<-1;
		}
		create project 	{
			type<-28;
			Niveau_act<-2;
		}
		create project 	{
			type<-28;
			Niveau_act<-3;
		}
		
		create project 	{
			type<-29;
			Niveau_act<-1;
		}
		create project 	{
			type<-29;
			Niveau_act<-2;
		}
		create project 	{
			type<-29;
			Niveau_act<-3;
		}
			
			

		create project from: new_erp {
				type<-30;
			}

			
		ask project {
			if Niveau_act=1 {cost<-5.0;}
			if Niveau_act=2 {cost<-10.0;}
			if Niveau_act=3 {cost<-15.0;}
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
		do define_buidling;
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
			type<-0;
			my_cells <- cell overlapping self;
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-myself.default_plu_net;
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
			my_cells <- cell overlapping self;
			altitude <- my_cells min_of(each.altitude);
			ask my_cells {
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
		
	 	
		float prev_alt<-0#m;
	 //	loop riv over:river_cells sort_by (each.location.x*100-each.location.y){
		loop riv over:river_cells sort_by (-each.location.x*100+each.location.y){
				riv.river_broad<-river_broad_normal;
				riv.river_depth<-river_depth_normal;
		 /* 		riv.altitude<-max([prev_alt+10#cm,riv.altitude]);			
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
				}*/
		}
		
		ask building where (each.name="building5313"){
			ask my_cells {
				altitude<-altitude-2#m;
				ask neighbors {altitude<-altitude-1#m;}
			}
			
			
		}
		
		prev_alt<-500#m;
		loop riv over:river_cells sort_by (each.location.x*100-each.location.y){
				riv.river_altitude<-min([riv.altitude-river_depth_normal,prev_alt-10#cm]);
				riv.river_depth<-riv.altitude-riv.river_altitude;
				prev_alt<-riv.river_altitude;
		}
		
		do create_spe_riv;
	}
	
	action create_spe_riv {
		create spe_riv from: bridge_shape_file {
				category<-0;
				list<cell> cell_impacted;
				cell_impacted<-cell where (each.is_river);
				cell_impacted<-cell_impacted where (self overlaps each);
				ask cell_impacted {
					river_depth<-min(1#m,river_depth/2);
					river_broad<-river_broad/4;
				}
			}

			create spe_riv from: ground_shape_file {
				category<-1;
						category<-0;
				list<cell> cell_impacted;
				cell_impacted<-cell where (each.is_river);
				cell_impacted<-cell_impacted where (self overlaps each);
				ask cell_impacted {
					river_depth<-min([0.5#m,river_depth/4]);
					river_broad<-river_broad/2;
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
	

		rivers <- union(river collect each.shape);
		using topology(world) {
			ask cell {
				is_active <- true;
			}
		}

		safe_roads <-road where ((each distance_to rivers) > 100#m );
	}
	
	

	
	action create_people {
		ask building where (each.category=0) {
			float it_max<-max(1,shape.area*nb_stairs/50);
			int it<-0;
			
			loop while: it<it_max {
			create people {
					my_number<-it;
					if (my_number/9)=mod(my_number,9) {want_to_follow_rules<-false;}
					if (my_number/3)=mod(my_number,3) {car_saver<-true;}
	
				my_building<-myself;
				starting_at_home<-true;
				 if starting_at_home {
				 	location<-myself.location;
				 }
				inside<-true;
				current_stair <- 0;
				have_car <- true;
				create car {
					my_owner <- myself;
					myself.my_car <- self;
					location <- myself.location;
					float dist <- 100 #m;
					is_parked<-false;
					
					using topology(world) {
						list<parking> free_parking <- parking where !each.is_full at_distance 200#m sort_by (each.name);
						parking closest_parking<- free_parking closest_to(myself);
						if closest_parking!=nil {
							location <-closest_parking.location;
							is_parked<-true;
							add self to:closest_parking.my_cars;
							closest_parking.nb_cars<-closest_parking.nb_cars+1;
							if closest_parking.nb_cars=closest_parking.capacity {closest_parking.is_full<-true;}
						}

						if !is_parked {
						list<road> roads_neigh <- (road where (each.category<2) at_distance dist) sort_by (each.name);
						loop while: empty(roads_neigh) {
							dist <- dist + 50;
							roads_neigh <- (road at_distance dist);
						}
						road a_road <- roads_neigh closest_to(myself);
						location <- a_road.location;
						my_owner.heading <- first(a_road.shape.points) towards last(a_road.shape.points);
						is_parked<-true;
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
					ask first(my_cars where (!each.is_parked)) {
						is_parked<-true;
						location <- g.location;
						cars<-cars-1;
						}
					}
				}	
				}

				
		ask people {
				if my_car distance_to rivers < 50#m {
					self.car_vulnerable<-true;
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
			
			dead_injuried_peoples<-[1,2,3,4,5];
			flooded_building_erps<-[1,2,3,4,5];
			routes_inondeess<-[0.1,0.2,0.3,0.5,0.8];
			flooded_building_prives<-[1,3,6,8,12];
			bien_endommages<-[0.001,0.01,0.05,0.1,0.2];
			flooded_cars<-[1,3,6,10,20];
		} 
		
			if flo_str=1 {
			time_simulation<-2#h;
			water_input_average<-30*10^4#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			rain_intensity_average<-1 #cm;
			time_start_rain<-0.25#h;
			time_last_rain<-1#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire

			dead_injuried_peoples<-[1,2,4,6,8];
			flooded_building_erps<-[1,2,3,4,6];
			routes_inondeess<-[0.1,0.3,0.5,0.8,1.2];
			flooded_building_prives<-[1,4,7,12,18];
			bien_endommages<-[0.002,0.02,0.1,0.2,0.3];
			flooded_cars<-[1,5,10,15,30];			
		} 
			 
			 
			 if flo_str=2 {
			time_simulation<-3#h;			
			water_input_average<-35*10^5#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2.5#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			rain_intensity_average<-1 #cm;
			time_start_rain<-1#h;
			time_last_rain<-1.1#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			dead_injuried_peoples<-[1,4,8,15,25];
			flooded_building_erps<-[1,3,5,7,10];
			routes_inondeess<-[0.1,0.4,0.8,1.2,1.6];
			flooded_building_prives<-[3,6,10,18,26];
			bien_endommages<-[0.005,0.05,0.15,0.3,0.5];
			flooded_cars<-[3,8,15,20,40];				
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
			
			dead_injuried_peoples<-[1,12,25,50,80];
			flooded_building_erps<-[1,3,6,9,12];
			routes_inondeess<-[0.2,0.6,1.0,1.6,2.3];
			flooded_building_prives<-[4,8,15,30,40];
			bien_endommages<-[0.01,0.08,0.2,0.4,0.6];
			flooded_cars<-[5,12,20,30,50];	
			}
			
			 
				if flo_str=4 {
			time_simulation<-2#h;
			water_input_average<-10*10^5#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			rain_intensity_average<-1.5 #cm;
			time_start_rain<-0#h;
			time_last_rain<-2#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			dead_injuried_peoples<-[1,20,40,70,120];
			flooded_building_erps<-[2,5,9,15,27];
			routes_inondeess<-[0.3,0.8,1.5,2.2,3.5];
			flooded_building_prives<-[5,15,25,35,60];
			bien_endommages<-[0.03,0.1,0.2,0.45,0.65];
			flooded_cars<-[7,15,25,40,70];	
		} 
		
		
			//test avec water input important
			if flo_str=5 {
			time_simulation<-3#h;
			water_input_average<-10*10^5#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			rain_intensity_average<-0.1 #cm;
			time_start_rain<-0#h;
			time_last_rain<-2#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			dead_injuried_peoples<-[1,10,25,60,110];
			flooded_building_erps<-[1,2,2,3,4];
			routes_inondeess<-[0.1,0.3,0.6,1,3];
			flooded_building_prives<-[10,40,100,200,300];
			bien_endommages<-[0.01,0.03,0.05,0.1,0.2];
			flooded_cars<-[1,10,20,35,50];	
		} 
		
		
		
			//test avec pluie importante
			if flo_str=6 {
			time_simulation<-3#h;
			water_input_average<-10*10^5#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2.5#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			rain_intensity_average<-1.5 #cm;
			time_start_rain<-0#h;
			time_last_rain<-2#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			dead_injuried_peoples<-[1,3,8,15,30];
			flooded_building_erps<-[0.01,0.1,0.2,0.5,0.8];
			routes_inondeess<-[0.2,0.6,1.0,1.6,2.3];
			flooded_building_prives<-[0.01,0.1,0.2,0.3,0.4];
			bien_endommages<-[0.01,0.04,0.08,0.15,0.3];
			flooded_cars<-[1,2,3,6,10];	
		} 
		
				//test avec pluie importante et input important
			if flo_str=7 {
			ask river_cells {water_volume<-20#m3;}
			time_simulation<-2#h;
			water_input_average<-10*10^5#m3/#h;
			time_start_water_input<-0#h;
			time_last_water_input<-2#h;
			water_intensity_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			rain_intensity_average<-1.5 #cm;
			time_start_rain<-0#h;
			time_last_rain<-2#h;
			rain_intensity_type<-0; 	//0 :const ; 1: croissant ; 2 : decroissant ; 3 : aleatoire
			
			dead_injuried_peoples<-[1,10,20,40,80];
			flooded_building_erps<-[5.0,15,30,50,70];
			routes_inondeess<-[0.5,1.0,2.0,5.0,8.5];
			flooded_building_prives<-[1.0,10,20,30,40];
			bien_endommages<-[0.01,0.05,0.15,0.25,0.35];
			flooded_cars<-[0.1,0.5,1,2,3];	
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
			write "Inondation de type : "+flo_str;
			first_flood_turn<-false;
			loop i from:0 to:int(time_last_rain/step) {
				add rain_intensity_average to:rain_intensity;
			}
			loop i from:0 to:int(time_last_water_input/step) {
				add water_input_average to:water_input_intensity;
			}
			do lack_maintenance_river;
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
			
			if !mode_test {write "Morts : "+dead_people;
			write "Blessés : "+injuried_people;
			write ("Voitures inondés : " +length(car where (each.domaged)));
			write ("Batiment inondé: " +length(building where (each.serious_flood)));
			write ("Max hauteur d'eau : " +max_water_he);
			write ("Nb de cells avec au moins 0.5m d'eau : "+length(flooded_cell));}
			do update_indicators;
			 write " ******************    Critères *****";
			 write "Logement : "+Crit_logement;
			 write "Infrastructure : "+Crit_infrastructure;
			 write "Economie : "+Crit_economie;
			 write "Bilan humain : "+Crit_bilan_humain;
			 write "Bilan Materiel prive : "+Crit_bilan_materiel_prive;
			 write "Bilan materiel public : "+Crit_bilan_materiel_public;
			 write "Sols : "+Crit_sols;
			 write "Satisfaction : "+Crit_satisfaction;
			 write "Environnement : "+Crit_environnement;

			
			 write "*******************************************";
			 
			if nb_turn>=nb_turn_test {code_test_end<-true;}
			else {nb_turn<-nb_turn+1;}
			write "nb tour : "+nb_turn;
			if !mode_test {do pause;}
			ask cell {
				water_volume<-0.0;
				do compute_water_altitude;	
			}
			
		}
		
	}	
	
	if !mode_flood {
		cost_proj_tot<-0.0;
		budget_espace_public<-0.0;
		budget_env<-0.0;
		budget_espace_public_moy<-0.0;
		budget_env_moy<-0.0;
		level_ent_green<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
		level_ent_dyke<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
 		level_ent_pluvial<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
		level_ent_nou<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
		level_ent_riv<-0; //0 : pas d'entretien, 1 : faible, 2: normal, 3 : amélioration
		time_flo<-time_flo+1 #y;
		nb_blesse<-"";
		nb_mort<-"";
		date_in<-string(time_flo.year);
		do reinitiate_indicators;
		write ("Phase de gestion");
	//	do pause;
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
do flowing;
//ask cell where (each.is_dyke and each.water_height>1#m) {do breaking_dyke;}

}


action flowing {
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
				if water_volume<=1 #m3 {already <- true;}
				else {
					already <- false;
					do compute_water_altitude;
			}
			}
			
		
			list<cell> flowing_cell <- cell where (each.water_volume>1 #m3);
			list<cell> cells_ordered <- flowing_cell sort_by (each.water_altitude);
		//	list<cell> cells_ordered <- flowing_cell sort_by (each.altitude);
			ask cells_ordered {do flow;}
			ask project{do making;}
			ask remove_duplicates((cell where (each.water_height > 0)) accumulate each.my_buildings) {do update_water;}
		//	ask car parallel: parallel_computation{do update_state;}
			ask car {do update_state;}
			ask road {do update_flood;}
			ask (cell where (each.water_height>=0.5#m)) { add self to:flooded_cell;}
			flooded_cell<-remove_duplicates(flooded_cell);
			ask building  {do update_water_color;}
			float max_wh_bd <- max(building collect each.water_height);
			float max_wh <- max(cell collect each.water_height);
			ask cell   {do update_color;}
	}
	
	

	action update_road {
		road_network_simple<-as_edge_graph(road where each.usable);
		current_weights <- road as_map (each::each.shape.perimeter / each.speed_coeff);
	}
	
	action update_road_work {
		rivers <- union(river collect each.shape);
		safe_roads <-road where ((each distance_to rivers) > 100#m );
		road_network_custom[list<int>([])] <- (as_edge_graph(road) use_cache false) with_shortest_path_algorithm #NBAStar;
		road_network_simple<-as_edge_graph(road);
		current_weights <- road as_map (each::each.shape.perimeter);
	}



action update_indicators {
	//******************indicateurs *******************
ask building {do compute_prix_moyen;}
ask people {do compute_satisfaction;}

densite<-length(people)/world.shape.area;  //ok
cout_vie<-(building where (each.category=0) sum_of(each.shape.area*(1+each.nb_stairs)))/nb_res_init*(building where (each.category=0)) mean_of(each.prix_moyen)/length(people);  // a modifier
invest_espace_public<-budget_espace_public/budget_espace_public_moy;
services<-length(building where (each.category=2)); //ok
entretien_reseau_plu<-level_ent_pluvial/3;
commerces<-length(building where (each.category=1)); //ok
flooded_building_erp<-100*length(building where (each.serious_flood and each.category=2))/length(building where (each.category=2)); //ok 
routes_inondees<-100*road where (each.is_flooded) sum_of(each.shape.perimeter)/road sum_of(each.shape.perimeter); //ok
flooded_building_prive<-100*length(building where (each.serious_flood and each.category<2))/length(building where (each.category<2)); //ok
bien_endommage<-1-mean(building collect each.state); //ok
flooded_car<-length(car where (each.domaged))/length(car)*100; //ok
taux_artificilisation<-100*(cell where (each.plu_typ=0)) sum_of(each.shape.area)/world.shape.area;  //ok
satisfaction<-people mean_of(each.satisfaction); //ok, mais a voir satisfaction
empreinte_carbone<-(project sum_of(each.empreinte_carbonne));
ratio_espace_vert<-100*length(cell  where (each.plu_typ=2))/length(cell  where (each.plu_typ=0)); //ok
biodiversite<-(project sum_of(each.biodiversite));
//(length(cell  where (each.plu_typ=3))+0.2*length(cell  where (each.plu_typ=2)))/length(cell); // à modifier
taux_budget_env<-budget_env/budget_env_moy;



//****************critere ******************


if cout_vie<0.4 {Crit_logement1<-5;}
else {if cout_vie<0.5 {Crit_logement1<-4;}
	else {if cout_vie<0.55 {Crit_logement1<-3;}
		else {if cout_vie<0.70 {Crit_logement1<-2;}
			else {if cout_vie<0.90 {Crit_logement1<-1;}
				else {Crit_logement1<-0;}
			}
		}
}
}
write "indicateurs : ";
write cout_vie;

if invest_espace_public<0.7 {Crit_logement2<-0;}
else {if invest_espace_public<0.85 {Crit_logement2<-1;}
	else {if invest_espace_public<1.05 {Crit_logement2<-2;}
		else {if invest_espace_public<1.2 {Crit_logement2<-3;}
			else {if invest_espace_public<1.3 {Crit_logement2<-4;}
				else {Crit_logement2<-5;}
			}
		}
}
}
write invest_espace_public;


Crit_logement<-round((Crit_logement1*W_cout_vie+Crit_logement2*W_invest_espace_public)/(W_cout_vie+W_invest_espace_public));

if services<25 {Crit_infrastructure1<-0;}
else {if services<28 {Crit_infrastructure1<-1;}
	else {if services<30 {Crit_infrastructure1<-2;}
		else {if services<32 {Crit_infrastructure1<-3;}
			else {if services<35{Crit_infrastructure1<-4;}
				else {Crit_infrastructure1<-5;}
			}
		}
}
}
write services;

if entretien_reseau_plu=0.4 {Crit_infrastructure2<-0;}
else {if entretien_reseau_plu<0.6 {Crit_infrastructure2<-1;}
	else {if entretien_reseau_plu<0.9 {Crit_infrastructure2<-2;}
		else {if entretien_reseau_plu<1.1 {Crit_infrastructure2<-3;}
			else {if entretien_reseau_plu<1.3{Crit_infrastructure2<-4;}
				else {Crit_infrastructure2<-5;}
			}
		}
}
}
write entretien_reseau_plu;
Crit_infrastructure<-round((Crit_infrastructure1*W_services+Crit_infrastructure2*W_entretien_reseau_plu)/(W_services+W_entretien_reseau_plu));


if commerces<250 {Crit_economie<-0;}
else {if commerces<270 {Crit_economie<-1;}
	else {if commerces<275 {Crit_economie<-2;}
		else {if commerces<280 {Crit_economie<-3;}
			else {if commerces<300{Crit_economie<-4;}
				else {Crit_economie<-5;}
			}
		}
}
}
write commerces;

if ((dead_people*10+injuried_people)<dead_injuried_peoples[0]) {Crit_bilan_humain<-5;}
else {if ((dead_people*10+injuried_people)<dead_injuried_peoples[1]) {Crit_bilan_humain<-4;}
	else {if ((dead_people*10+injuried_people)<dead_injuried_peoples[2]) {Crit_bilan_humain<-3;}
		else {if ((dead_people*10+injuried_people)<dead_injuried_peoples[3]) {Crit_bilan_humain<-2;}
			else {if ((dead_people*10+injuried_people)<dead_injuried_peoples[4]) {Crit_bilan_humain<-1;}
				else {Crit_bilan_humain<-0;}
			}
		}
}
}
			write dead_people*10+injuried_people;
		
			
if flooded_building_erp<flooded_building_erps[0] {Crit_bilan_materiel_public1<-5;}
else {if flooded_building_erp<flooded_building_erps[1] {Crit_bilan_materiel_public1<-4;}
	else {if flooded_building_erp<flooded_building_erps[2] {Crit_bilan_materiel_public1<-3;}
		else {if flooded_building_erp<flooded_building_erps[3] {Crit_bilan_materiel_public1<-2;}
			else {if flooded_building_erp<flooded_building_erps[4] {Crit_bilan_materiel_public1<-1;}
				else {Crit_bilan_materiel_public1<-0;}
			}
		}
}
}
write flooded_building_erp;

if routes_inondees<routes_inondeess[0] {Crit_bilan_materiel_public2<-5;}
else {if routes_inondees<routes_inondeess[1] {Crit_bilan_materiel_public2<-4;}
	else {if routes_inondees<routes_inondeess[2] {Crit_bilan_materiel_public2<-3;}
		else {if routes_inondees<routes_inondeess[3] {Crit_bilan_materiel_public2<-2;}
			else {if routes_inondees<routes_inondeess[4] {Crit_bilan_materiel_public2<-1;}
				else {Crit_bilan_materiel_public1<-0;}
			}
		}
}
}

		
			write routes_inondees;
			


Crit_bilan_materiel_public<-round((Crit_bilan_materiel_public1*W_flooded_building_erp+Crit_bilan_materiel_public2*W_routes_inondees)/(W_flooded_building_erp+W_routes_inondees));

if flooded_building_prive<flooded_building_prives[0] {Crit_bilan_materiel_prive1<-5;}
else {if flooded_building_prive<flooded_building_prives[1] {Crit_bilan_materiel_prive1<-4;}
	else {if flooded_building_prive<flooded_building_prives[2] {Crit_bilan_materiel_prive1<-3;}
		else {if flooded_building_prive<flooded_building_prives[3] {Crit_bilan_materiel_prive1<-2;}
			else {if flooded_building_prive<flooded_building_prives[4] {Crit_bilan_materiel_prive1<-1;}
				else {Crit_bilan_materiel_prive1<-0;}
			}
		}
}
}

	
			write flooded_building_prive;
			
if bien_endommage<bien_endommages[0] {Crit_bilan_materiel_prive2<-5;}
else {if bien_endommage<bien_endommages[1] {Crit_bilan_materiel_prive2<-4;}
	else {if bien_endommage<bien_endommages[2] {Crit_bilan_materiel_prive2<-3;}
		else {if bien_endommage<bien_endommages[3] {Crit_bilan_materiel_prive2<-2;}
			else {if bien_endommage<bien_endommages[4] {Crit_bilan_materiel_prive2<-1;}
				else {Crit_bilan_materiel_prive2<-0;}
			}
		}
}
}write bien_endommage;


if flooded_car=flooded_cars[0] {Crit_bilan_materiel_prive3<-5;}
else {if flooded_car<flooded_cars[1] {Crit_bilan_materiel_prive3<-4;}
	else {if flooded_car<flooded_cars[2] {Crit_bilan_materiel_prive3<-3;}
		else {if flooded_car<flooded_cars[3] {Crit_bilan_materiel_prive3<-2;}
			else {if flooded_car<flooded_cars[4] {Crit_bilan_materiel_prive3<-1;}
				else {Crit_bilan_materiel_prive3<-0;}
			}
		}
}
}
 write flooded_car;
			

Crit_bilan_materiel_prive<-round((Crit_bilan_materiel_prive1*W_flooded_building_prive+Crit_bilan_materiel_prive2*W_bien_endommage+Crit_bilan_materiel_prive3*W_flooded_car)/(W_flooded_building_prive+W_bien_endommage+W_flooded_car));


if taux_artificilisation>60 {Crit_sols<-0;}
else {if taux_artificilisation>50 {Crit_sols<-1;}
	else {if taux_artificilisation>40 {Crit_sols<-2;}
		else {if taux_artificilisation>30 {Crit_sols<-3;}
			else {if taux_artificilisation>20{Crit_sols<-4;}
				else {Crit_sols<-5;}
			}
		}
}
}
write taux_artificilisation;

if satisfaction< -0.8 {Crit_satisfaction<-0;}
else {if satisfaction< -0.6 {Crit_satisfaction<-1;}
	else {if satisfaction< -0.3 {Crit_satisfaction<-2;}
		else {if satisfaction< 0 {Crit_satisfaction<-3;}
			else {if satisfaction<0.2{Crit_satisfaction<-4;}
				else {Crit_satisfaction<-5;}
			}
		}
}
}
write satisfaction;

if empreinte_carbone< -0.8 {Crit_environnement1<-0;}
else {if empreinte_carbone< -0.5 {Crit_environnement1<-1;}
	else {if empreinte_carbone<0 {Crit_environnement1<-2;}
		else {if empreinte_carbone<0.5 {Crit_environnement1<-3;}
			else {if empreinte_carbone<0.8 {Crit_environnement1<-4;}
				else {Crit_environnement1<-5;}
			}
		}
}
}
write empreinte_carbone;

if ratio_espace_vert<1 {Crit_environnement2<-0;}
else {if ratio_espace_vert<2 {Crit_environnement2<-1;}
	else {if ratio_espace_vert<4 {Crit_environnement2<-2;}
		else {if ratio_espace_vert<5 {Crit_environnement2<-3;}
			else {if ratio_espace_vert<6 {Crit_environnement2<-4;}
				else {Crit_environnement2<-5;}
			}
		}
}
}
write ratio_espace_vert;

if biodiversite< -0.3 {Crit_environnement3<-0;}
else {if biodiversite< -0.15 {Crit_environnement3<-1;}
	else {if biodiversite<0.05 {Crit_environnement3<-2;}
		else {if biodiversite<0.5 {Crit_environnement3<-3;}
			else {if biodiversite<0.8{Crit_environnement3<-4;}
				else {Crit_environnement3<-5;}
			}
		}
}
}
write biodiversite;

if taux_budget_env<0.4 {Crit_environnement4<-0;}
else {if taux_budget_env<0.8 {Crit_environnement4<-1;}
	else {if taux_budget_env<1.1 {Crit_environnement4<-2;}
		else {if taux_budget_env<1.8 {Crit_environnement4<-3;}
			else {if taux_budget_env<3 {Crit_environnement4<-4;}
				else {Crit_environnement4<-5;}
			}
		}
}
}
write taux_budget_env;

Crit_environnement<-round((Crit_environnement4*W_taux_budget_env+Crit_environnement3*W_biodiversite+Crit_environnement2*W_ratio_espace_vert+Crit_environnement1*W_empreinte_carbone)/(W_taux_budget_env+W_biodiversite+W_ratio_espace_vert+W_empreinte_carbone));


write Crit_logement;
write Crit_infrastructure;
write Crit_economie;
write Crit_bilan_humain;
write Crit_bilan_materiel_prive;
write Crit_bilan_materiel_public;
write Crit_sols;
write Crit_satisfaction;
write Crit_environnement;



}



action lack_maintenance_river{
		ask river {
			ask my_cells {
				river_depth<-river_depth*myself.state;
				river_broad<-river_broad*myself.state;
			}
		}
}

//5	Réparation biens publics  							
//6	Entretien parcs et espaces verts					
//7	Réparation et entretien ouvrages de protection		
//8	Réparation et entretien du pluvial					
//9	Entretien noues et fossés							
//10	Entretien cours d’eau							
//19	Réparation bâtiments com et entrep
//20	Réparation logements

action compute_repair {
	//******************degradation************************
	 ask green_area{state<-state-0.1; }
	 ask pluvial_network{state<-state-0.1;}
	 ask river{state<-state-0.1;}
	 ask cell where each.is_dyke  {breaking_probability<-breaking_probability+0.01;}	
	 
	 //******************clacul des couts de remise en état************************
	 //Réparation biens publics
	float gcost<-0.0;
	float state_new;
	list<float> aim_state<-[0.8,1.0,1.1];	
	loop i from: 0 to:2 {
	gcost<-0.0;
	ask building where (each.category=2 and each.state<aim_state[i]) {
			gcost<-gcost+(aim_state[i]-state)*shape.area/2000;
		}
	ask road where (each.category=2 and each.state<aim_state[i]) {
			gcost<-gcost+(aim_state[i]-state)*shape.area/5000;
		}
		gcost<- round(gcost);	
	//	write "Coût de réparation des biens publics de niveau "+(i+1)+" : "+gcost;
		ask project where (each.type=5 and each.Niveau_act=i+1) {
			cost<-gcost;
		}
	}

	//entretien parcs
	gcost<-0.0;
	aim_state<-[0.8,1.0,1.1];	
	loop i from: 0 to:2 {
			gcost<-0.0;
			ask green_area where (each.state<aim_state[i]) {
			gcost<-gcost+(aim_state[i]-state)*shape.area/50000;
	}
	gcost<-round(gcost);			
	//write "Coût d'entretien des zones vertes de niveau "+(i+1)+" : "+gcost;
		ask project where (each.type=6 and each.Niveau_act=i+1) {
			cost<-gcost;
		}
	}
		
	//Réparation et entretien ouvrages de protection
		loop i from: 0 to:2 {
		gcost<-0.0;
		ask cell where each.is_dyke  {
				gcost<-gcost+breaking_probability*(i+1)*5;
			}	
			gcost<-round(gcost);
		//	write "Coût de réparation et entretien des ouvrages de protection de niveau "+(i+1)+" : "+gcost;
			ask project where (each.type=7 and each.Niveau_act=i+1) {
			cost<-gcost;
		}
	}
	
		 //Réparation et entretien du pluvial
			loop i from: 0 to:2 {
				gcost<-0.0;
				ask pluvial_network where (each.type=0) {
					gcost<-gcost+shape.perimeter/2*((i+1))/10000;
					state<-state+0.1*(i+1);
				}
			gcost<-round(gcost);		
	//		write "Coût de réparation et entretien du réseau pluvial de niveau "+(i+1)+" : "+gcost;
			ask project where (each.type=8 and each.Niveau_act=i+1) {
			cost<-gcost;
		}
		}
	
		//9	Entretien noues et fossés
			loop i from: 0 to:2 {
			gcost<-0.0;
			ask pluvial_network where (each.type=1){
					gcost<-gcost+shape.perimeter/2*(1+i)/10000;
			}
			gcost<-round(gcost);	
	//		write "Coût de réparation et entretien des noues de niveau "+(i+1)+" : "+gcost;
			ask project where (each.type=9 and each.Niveau_act=i+1) {
			cost<-gcost;
			}
			}
	
		//Entretien cours d’eau
			loop i from: 0 to:2 {
				gcost<-0.0;
				ask river {
					gcost<-gcost+shape.perimeter/2*(1+i)/1000;
				}
			gcost<-round(gcost);	
	//		write "Coût d'entretien de la rivière de niveau "+(i+1)+" : "+gcost;
			ask project where (each.type=10 and each.Niveau_act=i+1) {
			cost<-gcost;
			}
	}
	
	//Réparation des commerces
	gcost<-0.0;
	aim_state<-[0.8,1.0,1.1];	
	loop i from: 0 to:2 {
	gcost<-0.0;
	ask building where (each.category=1 and each.state<aim_state[i]) {
			gcost<-gcost+(aim_state[i]-state)*shape.area/3000;
		}
		gcost<- round(gcost);	
	//	write "Coût de réparation des commerces et bureaux "+(i+1)+" : "+gcost;
		ask project where (each.type=19 and each.Niveau_act=i+1) {
			cost<-gcost;
		}
	}
	
	//Réparation des logements
	gcost<-0.0;
	aim_state<-[0.8,1.0,1.1];	
	loop i from: 0 to:2 {
	gcost<-0.0;
	ask building where (each.category=0 and each.state<aim_state[i]) {
			gcost<-gcost+(aim_state[i]-state)*shape.area/4000;
		}
		gcost<- round(gcost);	
	//	write "Coût de réparation des logements "+(i+1)+" : "+gcost;
		ask project where (each.type=20 and each.Niveau_act=i+1) {
			cost<-gcost;
		}
	}
		
		budget_espace_public_moy<-(project where (each.Niveau_act=2 and (each.type=5 or each.type=6 or each.type=7 or each.type=8 or each.type=9 or each.type=10 or each.type=19 or each.type=20))) sum_of(each.cost);
		budget_env_moy<-(project where (each.Niveau_act=2 and (each.type=6 or each.type=9 or each.type=10))) sum_of(each.cost);
				

		if first_management_turn {
			ask project where (each.type=5 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=6 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=7 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=8 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=9 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=10 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=19 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=20 and each.Niveau_act=2) {do implement_project;}
		}
		else {do maintenance;}
		first_management_turn<-false;
}


//5	Réparation biens publics  							
//6	Entretien parcs et espaces verts					
//7	Réparation et entretien ouvrages de protection		
//8	Réparation et entretien du pluvial					
//9	Entretien noues et fossés							
//10	Entretien cours d’eau							
//19	Réparation bâtiments com et entrep
//20	Réparation logements

action maintenance {
	list<string> entretien_lbl<-[
		"Réparation biens publics", 							
		"Entretien parcs et espaces verts",			
		"Réparation et entretien ouvrages de protection",		
		"Réparation et entretien du pluvial",					
		"Entretien noues et fossés",							
		"Entretien cours d’eau",							
		"Réparation bâtiments com et entrep",
		"Réparation logements"	];
	
	list<float> cou<-[0.0,0.0,0.0,0.0];
	int i<-1;
			ask project where (each.type=5) {implemented<-false;}
			ask project where (each.type=6) {implemented<-false;}
			ask project where (each.type=7) {implemented<-false;}
			ask project where (each.type=8) {implemented<-false;}
			ask project where (each.type=9) {implemented<-false;}
			ask project where (each.type=10) {implemented<-false;}
			ask project where (each.type=19) {implemented<-false;}
			ask project where (each.type=20) {implemented<-false;}
									
	
	if mode_test {
			ask project where (each.type=5 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=6 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=7 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=8 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=9 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=10 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=19 and each.Niveau_act=2) {do implement_project;}
			ask project where (each.type=20 and each.Niveau_act=2) {do implement_project;}
	}
	
	if !mode_test {
	//5	Réparation biens publics 
	ask project where (each.type=5) {
		cou[i]<-cost;
		i<-i+1;
	}
	map result_level<-user_input_dialog(entretien_lbl[0], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}		
	i<-1;
	ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
	//6	Entretien parcs et espaces verts	
	ask project where (each.type=6) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[1], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}		
	i<-1;
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
	//7	Réparation et entretien ouvrages de protection		
	ask project where (each.type=7) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[2], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}	
	i<-1;
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
//8	Réparation et entretien du pluvial		
	ask project where (each.type=8) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[3], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}		
	i<-1;
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
//9	Entretien noues et fossés		
	ask project where (each.type=9) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[4], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}		
	i<-1;
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
//10	Entretien cours d’eau		
	ask project where (each.type=10) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[5], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}	
	i<-1;
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
//19	Réparation bâtiments com et entrep
	ask project where (each.type=19) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[6], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}		
	i<-1;
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
//20	Réparation logements	
	ask project where (each.type=20) {
		cou[i]<-cost;
		i<-i+1;
	}
	result_level<-user_input_dialog(entretien_lbl[7], [choose("Quel niveau de réparation/entretien ?",string,"Normal", ["Aucun : "+cou[0],"Limité : "+cou[1],"Normal : "+cou[2],"Elevé : "+cou[3]])]);
	if first(result_level)="Aucun" {niv<-0;}
	if first(result_level)="Limité" {niv<-1;}
	if first(result_level)="Normal" {niv<-2;}
	if first(result_level)="Elevé" {niv<-3;}	
	i<-1;	
		ask project where (each.type=action_type and each.Niveau_act=niv) {
		do implement_project;
		write "Niveau de réparation/entretien : "+result_level;
		write "Coût de cette action de maintenance : "+cost;
			}
	
}

}



action reinitiate_indicators  {
do compute_repair;
ask road where (each.is_flooded) {is_flooded<-false;}
ask road where (each.usable=false) {usable<-true;}
max_water_he<-0.0;
flooded_cell<-[];
ask building where (each.serious_flood) {serious_flood<-false;
	do update_water;
}
ask car where each.domaged {domaged<-false;
	do update_state;
}
ask people where each.injuried {injuried<-false;}
ask car where each.is_protected {is_protected<-false;}
ask people where each.is_protected {is_protected<-false;}
ask cell {
	is_critical<-false;
}
ask people {
	location<-my_building.location;
	inside<-true;
	current_stair <- 0;
	ask my_car {
	location <- myself.location;
	float dist <- 100 #m;
	is_parked<-false;
	using topology(world) {
			list<parking> free_parking <- parking where !each.is_full at_distance 200#m sort_by (each.name);
			parking closest_parking<- free_parking closest_to(myself);
			if closest_parking!=nil {
					location <-closest_parking.location;
					is_parked<-true;
					add self to:closest_parking.my_cars;
					closest_parking.nb_cars<-closest_parking.nb_cars+1;
					if closest_parking.nb_cars=closest_parking.capacity {closest_parking.is_full<-true;}
			}

			if !is_parked {
			list<road> roads_neigh <- (road where (each.category<2) at_distance dist) sort_by (each.name);
			loop while: empty(roads_neigh) {
							dist <- dist + 50;
							roads_neigh <- (road at_distance dist);
						}
						road a_road <- roads_neigh closest_to(myself);
						location <- a_road.location;
						my_owner.heading <- first(a_road.shape.points) towards last(a_road.shape.points);
						is_parked<-true;
						}	
					}	
		}
		
		}			
	
		ask parking {
			my_cars<-car overlapping self;
			if length(my_cars)>0 {
			ask my_cars {is_parked<-false;}
			int cars<-length(my_cars where (!each.is_parked));
			loop g over: to_squares(shape, 4#m, false) {
				 if cars>0 {
					ask first(my_cars where (!each.is_parked)) {
						is_parked<-true;
						location <- g.location;
						cars<-cars-1;
							}
						}
					}
				}		
}
injuried_people<-0;
dead_people<-0;
}

//******************************** USER COMMAND ****************************************


	//current action type
	int action_type <- -1;	
	bool second_point<-false;
	point first_location;
	int niv;
	
	
//0	Bassin arboré de rétention / infiltration
//1	Barrage écrêteur
//2	Extension zone N du PLU
//3	Création de fossés et noues (voirie)
//4	Aménager parcs et espaces verts
//5	Réparation biens publics
//6	Entretien parcs et espaces verts
//7	Réparation et entretien ouvrages de protection
//8	Réparation et entretien du pluvial
//9	Entretien noues et fossés
//10	Entretien cours d’eau
//11	Protections individuelles amovibles (logements)
//12	Murets de protection
//13	Achat biens confort / consommation
//14	Modifier PLU
//15	Délocaliser
//16	Protections individuelles (com et entrep.)
//17	Extension de la ZAC
//18	Construction commerces et entreprises en ville
//19	Réparation bâtiments com et entrep
//20	Réparation logements
//21	Densifier l'urbanisation
//22	Construction nouveau quartier 1
//23	Construction nouveau quartier 2
//24	Construction nouveau quartier 3
//25	Végétaliser toitures ZAC
//26	Végétaliser toitures (logements)
//27	Revêtements de sol perméables
//28	Puits infiltration
//29	Jardins de pluie
//30	Construction nouveau ERP
list<string> lab_proj<-[
"Bassin de retention",
"Barrage écrêteur",
"Extension zone N du PLU",
"Création de fossés et noues (voirie)",
"Aménager parcs et espaces verts",
"Réparation biens publics",
"Entretien parcs et espaces verts",
"Réparation et entretien ouvrages de protection",
"Réparation et entretien du pluvial",
"Entretien noues et fossés",
"Entretien cours d’eau",
"Protections individuelles amovibles (logements)",
"Murets de protection",
"Achat biens confort / consommation",
"Modifier PLU",
"Délocaliser",
"Protections individuelles (com et entrep.)",
"Extension de ZAC",
"Construction commerces et entreprises en ville",
"Réparation bâtiments com et entrep",
"Réparation logements",
"Densifier l'urbanisation",
"Construction nouveau quartier 1",
"Construction nouveau quartier 2",
"Construction nouveau quartier 3",
"Végétaliser toitures ZAC",
"Végétaliser toitures (logements)",
"Revêtements de sol perméables",
"Puits infiltration",
"Jardins de pluie",
"Construction nouveau ERP"];
	

	

	
	action activate_act {
		map result_level;
		button selected_but <- first(button overlapping (circle(1) at_location #user_location));
		if(selected_but != nil) {
			ask selected_but {
				action_type<-id;		
				//if (action_type != id) {action_type<-id;} 
				//else {action_type<- -1;}
			}
		
			if action_type>=0 and action_type<31 {
				result_level<-user_input_dialog(lab_proj[action_type], [choose("Quel niveau de projet ?",string,"Niveau 1", ["Niveau 1","Niveau 2", "Niveau 3"])]);
				if first(result_level)="Niveau 1" {niv<-1;}
				if first(result_level)="Niveau 2" {niv<-2;}
				if first(result_level)="Niveau 3" {niv<-3;}		
					
					ask project where (each.type=action_type and each.Niveau_act=niv) {
							write (lab_proj[action_type]+"  réalisé(e)(s) de niveau "+Niveau_act);
							do implement_project;
							write "Coût du projet : "+cost;
							
							
	
					}
			}				
	}
	
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
//*************************** OBSTACLE **********************************************************************
//***********************************************************************************************************
species obstacle {
	float height <- 2#m;
	float altitude;
	int resistance<-2;
	rgb color<-#violet;
	bool is_destroyed<-false;
	list<cell> my_cells;
	
	aspect default {
		draw shape+(0.5,10,#flat)  depth:height color: color at:location+{0,0,height};
	}
	
}



//***********************************************************************************************************
//***************************  GREEN AREA   **********************************************************************
//***********************************************************************************************************
species green_area {
	rgb color <- rgb(0,128,0,0.35);
	list<cell> my_cells;
	float state<-1.0;
	
	
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

float cost;
float volume;
float depth;
float water_into<-0.0;
float distance_application<-200#m;

float empreinte_carbonne; //[-1,+1] selon impact très négatif à très positif 
float biodiversite; //[-1,+1] selon impact très négatif à très positif


action implement_project {
//0	Bassin arboré de rétention / infiltration
//1	Barrage écrêteur
//2	Extension zone N du PLU
//3	Création de fossés et noues (voirie)
//4	Aménager parcs et espaces verts
//5	Réparation biens publics
//6	Entretien parcs et espaces verts
//7	Réparation et entretien ouvrages de protection
//8	Réparation et entretien du pluvial
//9	Entretien noues et fossés
//10	Entretien cours d’eau
//11	Protections individuelles amovibles (logements)
//12	Murets de protection
//13	Achat biens confort / consommation
//14	Modifier PLU
//15	Délocaliser
//16	Protections individuelles (com et entrep.)
//17	Extension de la ZAC
//18	Construction commerces et entreprises en ville
//19	Réparation bâtiments com et entrep
//20	Réparation logements
//21	Densifier l'urbanisation
//22	Construction nouveau quartier 1
//23	Construction nouveau quartier 2
//24	Construction nouveau quartier 3
//25	Végétaliser toitures ZAC
//26	Végétaliser toitures (logements)
//27	Revêtements de sol perméables
//28	Puits infiltration
//29	Jardins de pluie
//30	Construction nouveau ERP
	
	implemented<-true;
	cost_proj_tot<-cost_proj_tot+cost;
	
	if (type<25 or type=30) {	budget_espace_public<-budget_espace_public+cost;		} 
	if (type=0 or type=2 or type=3 or type=4 or type=6 or type=9 or type=10 or type=15 or type=25 or type=26 or type=27 or type=28 or type=29) {
						budget_env<-budget_env+cost;
		} 
	
	if type=0 { //bassin
	empreinte_carbonne<-0.05;
	biodiversite<-0.1;
	ask building overlapping self {
		ask people where (each.my_building=self) {
			my_building<-(building where (each.category=0)) closest_to self;
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
	satisfaction<-0.0;
	}
	ask parking  overlapping self {do die;}
	ask green_area  overlapping self {do die;}
	ask pluvial_network  overlapping self {do die;}
	ask obstacle  overlapping self {do die;}
	ask supp_roads {do die;}
	ask world {do update_road_work;	}
	my_cells<-cell overlapping self;
	my_neigh_cells<-cell where ((each distance_to self)<distance_application) +	my_neigh_cells;
	my_neigh_cells<-remove_duplicates(my_neigh_cells); 
}

	if type=1 { //barrage
			empreinte_carbonne<--0.1;
			biodiversite<-0.0;	
		create obstacle {
			shape<-myself.shape;
			location<-myself.location;
			height<-3#m*(myself.Niveau_act);
			my_cells <- cell overlapping self;
			altitude <- my_cells min_of(each.altitude);
			ask my_cells {
					is_dyke<-true;
					dyke_height<-myself.height;
					}
			}
	}

	if type=2 { //zone nat
			empreinte_carbonne<-0.1;
			biodiversite<-0.2;
		ask building overlapping self {
		ask people where (each.my_building=self) {
			my_building<-(building where (each.category=0)) closest_to self;
		}
			do die;	
		}
			ask parking  overlapping self {do die;}
			ask obstacle  overlapping self {do die;}
			create green_area {
				shape<-myself.shape;
				location<-myself.location;
				my_cells <- cell overlapping self;
				ask my_cells {
					plu_typ<-3;
					do see_plu;
				}
			}
}


	if type=3 { //noue
			empreinte_carbonne<-0.0;
			biodiversite<-0.05;
		create pluvial_network {
			type<-1;
			shape<-myself.shape;
			location<-myself.location;
			my_cells <- cell overlapping self;
			altitude <- my_cells min_of(each.altitude);
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-0.1#m3/#s;
			}
			}
}



	if type=4 { //Aménager parcs et espaces verts
		empreinte_carbonne<-0.1;
		biodiversite<-0.1;
		ask building overlapping self {
			ask people where (each.my_building=self) {
				my_building<-(building where (each.category=0)) closest_to self;
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
		satisfaction<-0.0;
		}
		ask parking  overlapping self {do die;}
		ask pluvial_network  overlapping self {do die;}
		ask obstacle  overlapping self {do die;}
		ask supp_roads {do die;}
		ask world {do update_road_work;	}
		my_cells<-cell overlapping self;
			create green_area {
				shape<-myself.shape;
				location<-myself.location;
				my_cells <- cell overlapping self;
				ask my_cells {
					plu_typ<-3;
					do see_plu;
				}
			}
		}



	if type=5 { //Réparation biens publics
		empreinte_carbonne<--0.01;
		biodiversite<-0.0;
}

	
	if type=6 { //6	Entretien parcs et espaces verts
		level_ent_green<-Niveau_act;
		float state_new;
		float aim_state;
		empreinte_carbonne<-0.0;
		biodiversite<-0.0;
		if Niveau_act=1 {aim_state<-0.8;}
		if Niveau_act=2 {aim_state<-1.0;}
		if Niveau_act=3 {aim_state<-1.1;}	
	}
	
		if type=7 { //7	Réparation et entretien ouvrages de protection
			level_ent_dyke<-Niveau_act;	
			empreinte_carbonne<--0.01;
			biodiversite<-0.0;
	}
	
		if type=8 { //8	Réparation et entretien du pluvial
			level_ent_pluvial<-Niveau_act;
			empreinte_carbonne<-0.0;
			biodiversite<-0.0;
		}
	
		if type=9 { //9	Entretien noues et fossés
			level_ent_nou<-Niveau_act;
			empreinte_carbonne<-0.0;
			biodiversite<-0.00;
	}
	
		if type=10 { //10	Entretien cours d’eau
				level_ent_riv<-Niveau_act;
				empreinte_carbonne<--0.00;
				biodiversite<-0.01;	
	}
	
		if type=11{ //11	Protections individuelles amovibles (logements)
		empreinte_carbonne<--0.05;
		biodiversite<--0.05;
		list<building> or_res_bd <- building where (each.category=0) sort_by (each distance_to rivers);
		int nb_bd; 
		if Niveau_act=1 {nb_bd<-int(length(building where (each.category=1))/10);}
		if Niveau_act=2 {nb_bd<-int(length(building where (each.category=1))/4);}
		if Niveau_act=3 {nb_bd<-int(length(building where (each.category=1))/2);}	
		int it<-0;
		loop bd over: or_res_bd {
			if it<nb_bd {
			bd.impermeability<-bd.impermeability+0.5;	
			}
			it<-it+1;
		}
	
	
	}
	
		if type=12{ //12	Murets de protection
		empreinte_carbonne<--0.05;
		biodiversite<--0.05;
		list<cell> or_cell <- cell where (each.plu_typ<2) sort_by (each.location.x*100-each.location.y);
		int nb_cl; 
		if Niveau_act=1 {nb_cl<-int(length(cell where (each.plu_typ<2))/20);}
		if Niveau_act=2 {nb_cl<-int(length(cell where (each.plu_typ<2))/10);}
		if Niveau_act=3 {nb_cl<-int(length(cell where (each.plu_typ<2))/4);}	
		int it<-0;
		loop cl over: or_cell {
			if nb_cl<it {
				cl.is_dyke<-true;
				cl.dyke_height<-1#m;
					}
			it<-it+1;
		}
				
	
	}
	
		if type=13 { //13	Achat biens confort / consommation
		empreinte_carbonne<--0.01;
		biodiversite<-0.00;
		int nb_peo; 
		if Niveau_act=1 {nb_peo<-int(length(people)/20);}
		if Niveau_act=2 {nb_peo<-int(length(people)/10);}
		if Niveau_act=3 {nb_peo<-int(length(people)/4);}	
		int it<-0;
		loop po over: people {
			if it<nb_peo {
				ask po.my_building {
					value<-min([1,value+0.2]);
					vulnerability<-min([1,vulnerability+0.1]);
				}

			}
			it<-it+1;
		}
	
	
	}
	
		if type=14 { //14	rien pour l'instant
	
	
	
	}
	
		if type=15{ //15	Délocaliser
		empreinte_carbonne<-0.0;
		biodiversite<-0.0;
		list<building> fd_bd <- building where (each.serious_flood) sort_by (-each.history_water_heigth);
		int nb_bd; 
		if Niveau_act=1 {nb_bd<-int(length(fd_bd)/20);}
		if Niveau_act=2 {nb_bd<-int(length(fd_bd)/10);}
		if Niveau_act=3 {nb_bd<-int(length(fd_bd)/4);}	
		int it<-0;
		loop bd over:fd_bd {
			if it<nb_bd {
				ask people where (each.my_building=bd) {
			my_building<-(building where (each.category=0)) closest_to self;
		}
		do die;
			}
			it<-it+1;
		}
	
	
	
	}
	
		if type=16{ //16	Protections individuelles (com et entrep.)
		empreinte_carbonne<--0.05;
		biodiversite<--0.05;
		list<building> or_res_bd <- building where (each.category=1) sort_by (each distance_to rivers);
		int nb_bd; 
		if Niveau_act=1 {nb_bd<-int(length(building where (each.category=1))/10);}
		if Niveau_act=2 {nb_bd<-int(length(building where (each.category=1))/4);}
		if Niveau_act=3 {nb_bd<-int(length(building where (each.category=1))/2);}	
		int it<-0;
		loop bd over: or_res_bd {
			if it<nb_bd {
			bd.impermeability<-bd.impermeability+0.5;	
			}
			it<-it+1;
		}
	
	
	}
	
		if type=17 { //17	Extension de la ZAC
		empreinte_carbonne<--0.1;
		biodiversite<--0.1;
				
				//a modifier avec les bons fichiers
				create building from: new_log1 {
				category<-0;
				do define_buidling;
			}	
			
			create road from: new_rou1 {
				category<-0;
				color<-color_category[category];
				my_cells <- cell overlapping self;
			}	
		
			create parking from: new_par1 {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells{
				is_parking<-true;
			}
		}
	
			create pluvial_network from:new_nou1 {
				type<-1;
				shape<-myself.shape;
				location<-myself.location;
				my_cells <- cell overlapping self;
				altitude <- my_cells min_of(each.altitude);
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-0.2#m3/#s;
			}
			}
	
					
		create pluvial_network from: new_plu1{
			if not (self overlaps world) {
				do die;
			}
			type<-0;
			my_cells <- cell overlapping self;
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-myself.default_plu_net;
			}
		}
	
	
	}

		if type=18{ //18	Construction commerces et entreprises en ville
			//distinger le s3 niveaux d'action
			empreinte_carbonne<--0.05;
			biodiversite<--0.05;
			create building from: new_com {
				category<-1;
				do define_buidling;
			}	
	
	
	
	}
	
		if type=19{ //19	Réparation bâtiments com et entrep
		float state_new;
		float aim_state;
		empreinte_carbonne<-0.0;
		biodiversite<-0.0;
		if Niveau_act=1 {aim_state<-0.8;}
		if Niveau_act=2 {aim_state<-1.0;}
		if Niveau_act=3 {aim_state<-1.1;}	
	}
	
		if type=20 { //20	Réparation logements
		float state_new;
		float aim_state;
		empreinte_carbonne<-0.0;
		biodiversite<-0.0;
		if Niveau_act=1 {aim_state<-0.8;}
		if Niveau_act=2 {aim_state<-1.0;}
		if Niveau_act=3 {aim_state<-1.1;}	
	}
	
		if type=21 { //21	Densifier l'urbanisation
		empreinte_carbonne<--0.1;
		biodiversite<--0.05;
			create building {
				shape<-myself.shape;
				location<-myself.location;
				category<-0;
				do define_buidling;
			}
	
	
	}
	
		if type=22{ //22	Construction nouveau quartier 1
		empreinte_carbonne<--0.1;
		biodiversite<--0.1;
			create building from: new_log1 {
				category<-0;
				do define_buidling;
			}	
			
			create road from: new_rou1 {
				category<-0;
				color<-color_category[category];
				my_cells <- cell overlapping self;
			}	
		
			create parking from: new_par1 {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells{
				is_parking<-true;
			}
		}
	
			create pluvial_network from:new_nou1 {
				type<-1;
				shape<-myself.shape;
				location<-myself.location;
				my_cells <- cell overlapping self;
				altitude <- my_cells min_of(each.altitude);
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-0.2#m3/#s;
			}
			}
	
					
		create pluvial_network from: new_plu1{
			if not (self overlaps world) {
				do die;
			}
			type<-0;
			my_cells <- cell overlapping self;
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-myself.default_plu_net;
			}
		}
	
	}
	
		if type=23{ //23	Construction nouveau quartier 2
		empreinte_carbonne<--0.1;
		biodiversite<--0.1;
		create building from: new_log2 {
				category<-0;
				do define_buidling;
			}	
			
			create road from: new_rou2 {
				category<-0;
				color<-color_category[category];
				my_cells <- cell overlapping self;
			}	
		
			create parking from: new_par2 {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells{
				is_parking<-true;
			}
		}
	
			create pluvial_network from:new_nou2 {
				type<-1;
				shape<-myself.shape;
				location<-myself.location;
				my_cells <- cell overlapping self;
				altitude <- my_cells min_of(each.altitude);
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-0.2#m3/#s;
			}
			}
	
					
		create pluvial_network from: new_plu2{
			if not (self overlaps world) {
				do die;
			}
			type<-0;
			my_cells <- cell overlapping self;
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-myself.default_plu_net;
			}
		}
	
	
	}
	
		if type=24 { //24	Construction nouveau quartier 3
		empreinte_carbonne<--0.1;
		biodiversite<--0.1;
		create building from: new_log3 {
				category<-0;
				do define_buidling;
			}	
			
			create road from: new_rou3 {
				category<-0;
				color<-color_category[category];
				my_cells <- cell overlapping self;
			}	
		
			create parking from: new_par3 {
			if not (self overlaps world) {
				do die;
			}
			my_cells <- cell overlapping self;
			ask my_cells{
				is_parking<-true;
			}
		}
	
			create pluvial_network from:new_nou3 {
				type<-1;
				shape<-myself.shape;
				location<-myself.location;
				my_cells <- cell overlapping self;
				altitude <- my_cells min_of(each.altitude);
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-0.2#m3/#s;
			}
			}
	
					
		create pluvial_network from: new_plu3{
			if not (self overlaps world) {
				do die;
			}
			type<-0;
			my_cells <- cell overlapping self;
			ask my_cells{
				is_pluvial_network<-true;
				water_evacuation_pl_net<-myself.default_plu_net;
			}
		}
	
	
	}
		

			

		if type=25 { //25	Végétaliser toitures ZAC
		empreinte_carbonne<-0.02;
		biodiversite<-0.0;
		list<building> or_com_bd <- building where (each.category=1 and each.location.x<1287 and each.location.y>1310) sort_by (each.location.x*100-each.location.y);
		int nb_bd; 
		if Niveau_act=1 {nb_bd<-int(length(or_com_bd)/5);}
		if Niveau_act=2 {nb_bd<-int(length(or_com_bd)/2);}
		if Niveau_act=3 {nb_bd<-int(length(or_com_bd)/1);}	
		int it<-0;
		loop bd over: or_com_bd {
			if nb_bd>it {
				bd.vegetalise<-true;
			}
		it<-it+1;
		}

	}
	
		if type=26 { //26	Végétaliser toitures (logements)
		empreinte_carbonne<-0.02;
		biodiversite<-0.0;
		list<building> or_res_bd <- building where (each.category=0) sort_by (each.location.x*100-each.location.y);
		int nb_bd; 
		if Niveau_act=1 {nb_bd<-int(length(building where (each.category=0))/20);}
		if Niveau_act=2 {nb_bd<-int(length(building where (each.category=0))/10);}
		if Niveau_act=3 {nb_bd<-int(length(building where (each.category=0))*3/10);}	
		int it<-0;
		loop bd over: or_res_bd {
			if nb_bd>it {
				bd.vegetalise<-true;
			}
			it<-it+1;
		}

	
	}
	
		if type=27{ //27	Revêtements de sol perméables
		empreinte_carbonne<-0.01;
		biodiversite<-0.0;
	list<cell> or_cell <- cell where (each.plu_typ=0) sort_by (each.location.x*100-each.location.y);
	int nb_cl; 
		if Niveau_act=1 {nb_cl<-int(length(cell where (each.plu_typ=0))/10);}
		if Niveau_act=2 {nb_cl<-int(length(cell where (each.plu_typ=0))/4);}
		if Niveau_act=3 {nb_cl<-int(length(cell where (each.plu_typ=0))/2);}	
		int it<-0;
		loop cl over: or_cell {
			if nb_cl>it {
				cl.permeabilise<-true;
			}
			it<-it+1;
		}
	

	}
	
		if type=28{ //28	Puits infiltration
	empreinte_carbonne<-0.0;
		biodiversite<-0.0;
	list<cell> or_cell <- cell where (each.plu_typ=0) sort_by (each.location.x*100-each.location.y);
	int nb_cl; 
		if Niveau_act=1 {nb_cl<-int(length(cell where (each.plu_typ=0))/10);}
		if Niveau_act=2 {nb_cl<-int(length(cell where (each.plu_typ=0))/4);}
		if Niveau_act=3 {nb_cl<-int(length(cell where (each.plu_typ=0))/2);}	
		int it<-0;
		loop cl over: or_cell {
			if nb_cl>it {
				cl.puits_infiltration<-true;
			}
			it<-it+1;
		}
	
		list<cell> bb<-cell where each.puits_infiltration;
	
	
	
	}
	
		if type=29 { //29	Jardins de pluie
	empreinte_carbonne<-0.0;
		biodiversite<-0.1;
	list<cell> or_cell <- cell where (each.plu_typ=0) sort_by (each.location.x*100-each.location.y);
	int nb_cl; 
		if Niveau_act=1 {nb_cl<-int(length(cell where (each.plu_typ=0))/10);}
		if Niveau_act=2 {nb_cl<-int(length(cell where (each.plu_typ=0))/4);}
		if Niveau_act=3 {nb_cl<-int(length(cell where (each.plu_typ=0))/2);}	
		int it<-0;
		loop cl over: or_cell {
			if nb_cl>it {
				cl.jardin_pluie<-true;
			}
			it<-it+1;
		}
	
	
	}


		if type=30{ //30	Construction nouveau ERP
	 		empreinte_carbonne<--0.05;
			biodiversite<--0.05;
	 		create building from: new_erp {
			category<-2;
			do define_buidling;
		}
	
	
	}







	


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
	if visible {
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
	float state<-1.0;

	action update_flood {
		cell_water_max <- max(my_cells collect each.water_height);
		speed_coeff <- 1.0 / (1 + cell_water_max) ;
		usable <- true;
		if cell_water_max > 20 #cm {
			usable <- false;
			is_flooded<-true;
			not_usable_roads << self;
			state<-min([state,30#cm/cell_water_max]);
		}
		

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
	float state<-1.0;
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
	int type; //type 0 : gris, 1 : noue
	list<cell> my_cells;
	float water_height <- 0 #m;
	float altitude;
	point my_location;
	float area_capacity<-1#m2;
	float default_plu_net<-0.1#m3/#s;
	float state<-1.0;

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
	float impermeability_init <- 0.7 ; //1: impermeable, 0:permeable
	float max_impermeability <- impermeability_init + max_impermeability_building_increase max: 1.0;
	float impermeability <- impermeability_init max: max_impermeability; 
	float water_height <- 0.0;
	float history_water_heigth;
	float water_evacuation <- 0.5 #m3 / #mn;
	point my_location;
	float bd_height ;
	float state <- 1.0; //entre 0 et 1
	float init_vulnerability <- 0.7;
	float min_vulnerability <- init_vulnerability - max_vulnerability_building_decrease min: 0.0;
	float vulnerability  <- init_vulnerability min: min_vulnerability; //between 0.1 et 1 (very vulnerable) 
	float value;  //0: vide aucune valeur -> 1. valeur très très forte
	bool is_water;
	rgb my_color <- #grey;
	bool nrj_on <- true;
	bool vegetalise<-false;
	int nb_stairs<--1;
	bool serious_flood<-false; 
	float water_level_flooded<-1#cm;
	
	
	
	bool neighbour_water <- false ;
	bool water_cell <- false;
	
		action define_buidling {
			my_cells <- cell overlapping self;
			ask my_cells {
				add myself to: my_buildings;
				myself.my_neighbour_cells <- (myself.my_neighbour_cells + neighbors);
			}
			
			
			
			my_neighbour_cells <- remove_duplicates(my_neighbour_cells);
			altitude <- (my_cells mean_of (each.altitude));
			my_location <- location + point(0, 0, altitude + 1 #m);
			if category=0 {
				my_color <- #grey;
				if (shape.area<70 and shape.area>40) {nb_stairs<-0;}
				if (shape.area<150 and shape.area>140) {nb_stairs<-1;}
				if (shape.area<420 and shape.area>350) {nb_stairs<-1;}
				if (shape.area<500 and shape.area>420) {nb_stairs<-2;}
				if (shape.area>1000) {nb_stairs<-3;}
			}
			if category=1 {
				my_color <- #yellow;
				if (shape.area<300 and shape.area>200) {nb_stairs<-0;}
				if (shape.area<2000 and shape.area>1000) {nb_stairs<-1;}
				if (shape.area<3000 and shape.area>2000) {nb_stairs<-1;}
				if (shape.area<5000 and shape.area>4000) {nb_stairs<-2;}
				if (shape.area>10000) {nb_stairs<-2;}
			}
			if category=2 {
				my_color <- #violet;
				nb_stairs<-1;
			}
			if nb_stairs=-1{write "pas glop : "+shape.area + " ; category : "+category;}
			bd_height<-(1+nb_stairs)*3.0;
	}
	
		
	action update_water {
		float cell_water_max;
		cell_water_max <- max(my_cells collect each.water_height);

		
		if water_height<cell_water_max {
			water_height <-water_height + (cell_water_max-water_height)* (1 - impermeability);
		}
		else {
			water_height <- max([0,water_height - (water_evacuation / shape.area * step/1#mn)]);
		}
		history_water_heigth<-max([history_water_heigth,water_height]);
		state <- min([state,max([0, state - (water_height / 10#m / (step / (1 #mn))) * vulnerability])]);
		if water_height>water_level_flooded {
			serious_flood<-true;
		}
		if not water_cell {
			water_cell <- cell_water_max >  10#cm;
		
		}
		if not neighbour_water {
			neighbour_water <- (my_neighbour_cells first_with (each.water_height > 10#cm)) != nil;
		
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

	action compute_prix_moyen {
		prix_moyen<-2000.0*state*(1+value);
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
	float problem_water_height<-30#cm;
	bool usable<-true;
	bool is_parked<-false;
	bool is_protected<-false;
	
	init {
		do define_cell;
	}
		
	action define_cell {
		my_cell<-cell(location);
		if my_cell=nil {my_cell<-cell closest_to(self);}
		
	}
	action update_state {
		if (!is_protected and my_cell.water_height>problem_water_height) {domaged<-true;}
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
	building my_current_building;
	car my_car;
	bool have_car;
	
	int current_stair;
	
	point my_location;
	bool in_car <- false;
	bool inside<-true;
	bool injuried<-false;
	bool starting_at_home;

	bool is_protected<-false;
	bool want_to_follow_rules<-true;
	bool car_saver<-false;
	int my_number;
	bool know_flood_is_coming<-false;
	bool know_rules<-false;
	bool car_vulnerable<-false;
		
		
	float satisfaction<-0.0; //-1: not satisfy at all, 1: very satisfied
	float proba_agenda<-0.05;  // quand il pleut, pas trop envie d'aller se promener
	float informed_on_flood<-0.8;
	float informed_on_rules<-0.3;
	
	float flooded_road_percep_distance<-1000#m;
	
	float water_height_danger_car <- 120 #cm;
	float water_height_danger_pied <- 180 #cm;
	float water_height_perception <- 10 #cm;
	float water_height_danger_inside_energy_on <- 60 #cm;
	float water_height_problem <- 20 #cm;
	float water_height_danger_inside_energy_off <- 150 #cm;
	
	
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
	bool doing_protect_properties<-false; 
	bool doing_turn_off_nrj<-false;  
	bool doing_weather_strip_house<-false;
 	bool doing_give_information<-false;
 	bool doing_go_upstair<-false;
	bool action_ending<-true;
	
	list<int> known_blocked_roads;
	
	graph current_graph;
	float outside_test_period <-20 #mn;
	cell my_current_cell;
	
	float water_level <- 0.0;
	float prev_water_inside <- 0.0;
	float prev_water_outside <- 0.0;
	float max_danger_inside<-0.0;
	float max_danger_outside<-0.0;
	
	
	

	reflex acting when:mode_flood {
		my_current_cell<-one_of(cell overlapping self);
		if ((time mod 10#mn) = 0 and !is_protected) {do test_danger;} 
		do my_perception;
		do update_danger;
		
		if know_flood_is_coming and (time mod 2#mn) {
		if action_ending and know_flood_is_coming and want_to_follow_rules  {
				doing_rules<-true;
				doing_agenda<-false;
				doing_evacuate<-false;
				doing_protect_car<-false;
				doing_protect_properties<-false; 
				doing_turn_off_nrj<-false;  
				doing_weather_strip_house<-false;
 				doing_give_information<-false;
 				doing_go_upstair<-false;
 				action_ending<-false;
			}
			 
		
		if action_ending and fear_level>0.6 {
				doing_evacuate<-true;
				doing_agenda<-false;
				doing_protect_car<-false;
				doing_evacuate<-false;
				doing_rules<-false;
				doing_protect_properties<-false; 
				doing_turn_off_nrj<-false;  
				doing_weather_strip_house<-false;
 				doing_give_information<-false;
 				doing_go_upstair<-false;
 				action_ending<-false;
		}
	
		if  action_ending and have_car and fear_level<0.2 and car_saver and car_vulnerable{
			doing_protect_car<-true;
			doing_agenda<-false;
			doing_evacuate<-false;
			doing_rules<-false;
			doing_protect_properties<-false; 
			doing_turn_off_nrj<-false;  
			doing_weather_strip_house<-false;
 			doing_give_information<-false;
 			doing_go_upstair<-false;
 			action_ending<-false;
		}
		
		if action_ending and fear_level>0.5 {
			doing_protect_car<-false;
			doing_agenda<-false;
			doing_evacuate<-false;
			doing_rules<-false;
			doing_protect_properties<-false; 
			doing_turn_off_nrj<-false;  
			doing_weather_strip_house<-false;
 			doing_give_information<-false;
 			doing_go_upstair<-false;
 			action_ending<-false;
 			 
		}
		
			if action_ending and fear_level>=0.3 {
			doing_protect_car<-false;
			doing_agenda<-false;
			doing_evacuate<-false;
			doing_rules<-false;
			doing_protect_properties<-false; 
			doing_turn_off_nrj<-false;  
			doing_weather_strip_house<-false;
 			doing_give_information<-false;
 			doing_go_upstair<-false;
 			action_ending<-false;
 			
 			if my_building.nrj_on=true {
				doing_turn_off_nrj<-true;
 			}
 			else {
 				if (current_stair<my_building.nb_stairs) {
 				doing_go_upstair<-true;	
 				}
 				else {
 					doing_give_information<-true;
 				}
 				
 			}
 			
		}
		if action_ending and fear_level<0.3 {
			doing_protect_car<-false;
			doing_agenda<-false;
			doing_evacuate<-false;
			doing_rules<-false;
			doing_protect_properties<-false; 
			doing_turn_off_nrj<-false;  
			doing_weather_strip_house<-false;
 			doing_give_information<-false;
 			doing_go_upstair<-false;
 			action_ending<-false;
 			if my_number/2=mod(my_number,2) {
 				doing_protect_properties<-true; 
 			}
 			else {
 				doing_weather_strip_house<-true;	
 			}
		}
}		
		
		
		
		if ((time mod 10#mn) = 0 and !doing_rules and !doing_evacuate and !doing_protect_car and !doing_protect_properties and !doing_turn_off_nrj 
			and !doing_weather_strip_house and !doing_give_information and !doing_go_upstair){
				if my_number/5=mod(my_number,5) {
			doing_agenda<-true;
			doing_rules<-false;
			doing_evacuate<-false;
			doing_protect_car<-false;
			doing_protect_properties<-false; 
			doing_turn_off_nrj<-false;  
			doing_weather_strip_house<-false;
 			doing_give_information<-false;
 			doing_go_upstair<-false;
 			action_ending<-false;
		}
		}
		
		
		if (doing_agenda) {do agenda;}
		if (doing_evacuate) {do evacuate;}
		if doing_protect_car {do protect_my_car;}
		if (doing_rules) {do follow_rules;}
		if (doing_protect_properties) {do protect_properties;}
		if (doing_turn_off_nrj) {do turn_off_nrj;}
		if (doing_weather_strip_house) {do weather_strip_house;}
 		if (doing_give_information) {do give_information;}
 		if (doing_go_upstair) {do go_upstair;}
		
 
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
		
		
		if my_current_cell.water_height>0 {
			know_flood_is_coming<-true;
			fear_level<-fear_level+0.005;
		}
		

		if inside {
			my_current_building<-one_of(building overlapping self);
			float whp <- water_height_perception;
			water_cell <- my_current_building.water_cell;
			water_cell_neighbour <-my_current_building.neighbour_water;
			water_level <- my_current_building.water_height;
			prev_water_inside <- my_current_building.water_height ;
			
			if my_current_building.water_height >= water_height_problem {
				fear_level<-fear_level+0.01;	
			}
			
			if my_current_building.water_height >= water_height_problem {
				water_building <- true;
				if current_stair<my_current_building.nb_stairs {current_stair<-my_current_building.nb_stairs;}
				if my_current_building.nb_stairs=0 {fear_level<-fear_level+0.2;}
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
			if (my_current_building.water_height >(3*(current_stair))) {
					if (my_current_building.nrj_on) {
						danger_inside <- min([danger_inside,min([1.0, ((my_current_building.water_height-(3*current_stair))/water_height_danger_inside_energy_on)])]); //entre 0 et 1 (1 danger de mort imminente) 
					}else {
						danger_inside <- min([danger_inside,min([1.0, ((my_current_building.water_height-(3*current_stair))/water_height_danger_inside_energy_off)])]); //entre 0 et 1 (1 danger de mort imminente) 
					}
					if danger_inside >0 {
						max_danger_inside <- max(max_danger_inside, danger_inside);
					}
				}		
		}
		else if my_current_cell != nil{
			float wh<-my_current_cell.water_height; 
			if in_car {danger_outside<-max([danger_outside,max([0,min([1.0, wh/water_height_danger_car])])]);	}
			else {danger_outside<-max([danger_outside,max([0,min([1.0, wh/water_height_danger_pied])])]);}
			if danger_outside >0 {
				max_danger_outside <- max(max_danger_outside, danger_outside);				
			}
		}
		if injuried {fear_level<-fear_level+0.2;}

	}
	
	
	action test_danger  {
		if max_danger_outside=1 or max_danger_inside=1 {do to_die;} 
		else {if max_danger_outside>0.5 or max_danger_inside>0.5 {
							injuried<-true;
							injuried_people <- injuried_people+1;
				if inside {injuried_inside<-injuried_inside+1;}
				if in_car {injuried_in_car<-injuried_in_car+1;}
				if !inside {injuried_outside<-injuried_outside+1;}
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
						if inside {die_inside<-die_inside+1;}
				if in_car {die_in_car<-die_in_car+1;}
				if !inside {die_outside<-die_outside+1;}
		do die;
		
	}
		
	action agenda{
			current_stair<-0;
			inside<-false;
			if (final_target = nil) {
				if location=my_building.location {my_destination_building<- (building where (each.category>0)) closest_to(self);}
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
					action_ending<-true;
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
					if (in_car) {ask my_car {is_protected<-true;}}
					is_protected<-true;
					action_ending<-true;
				} else {
					in_car <- true;
					current_target <- final_target;
				}
			}
		}
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
		
		if (location = current_target) {current_graph <- nil;	}			
	}
	

	action follow_rules {
		if location=my_building.location {
		inside<-true;
		if my_building.nrj_on {do turn_off_nrj;}
		else {
			if my_building.nb_stairs>0 and fear_level>0.2 {do go_upstair;}
			else if fear_level>0.1{do protect_properties;}
			else {do weather_strip_house;}
		}
		if my_number/5=mod(my_number,5) {do give_information;}
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
				action_ending<-true;
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


	action go_upstair {
		current_stair <- my_building.nb_stairs;
		action_ending<-true;
	}
	
	
	action protect_properties {
		current_stair<-0;
		my_building.vulnerability <- my_building.vulnerability - (0.2 * step / 1 #h);
		action_ending<-true;
	}


	action turn_off_nrj  {
		current_stair<-0;
		my_building.nrj_on <- false;
		action_ending<-true;
	}


	action weather_strip_house {
		current_stair<-0;
		my_building.impermeability <- my_building.impermeability + (0.05*step / 1 #h);
		action_ending<-true;
	}
	



	action give_information {
		ask (people where (each.my_number=self.my_number+2)) {
			if myself.know_rules {know_rules<-true;}
			know_flood_is_coming<-true;
		}
		action_ending<-true;
	}



	action protect_my_car {
		inside<-false;
		current_stair <- 0;	
		speed <- my_speed();
		if (final_target = nil) {
			road a_road <- safe_roads closest_to self;
			final_target <- a_road.location;
			current_target <- my_car.location;
		} else {
			do moving;
			if( in_car) {
				my_car.location <- location;
			}
			if (current_target = location) {
				if (current_target = final_target) {
					in_car <- false;
					current_target <- my_building.location;
					return_home <- true;
					action_ending<-true;
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

	action compute_satisfaction  {
		satisfaction<-0.0;
		satisfaction<-satisfaction+my_building.value+my_building.state-1;
		satisfaction<-satisfaction+(green_area  sum_of(each.shape.area)-nb_park_init)/nb_park_init; 
		satisfaction<-satisfaction+(((building where (each.category=2)) mean_of each.state*length(building where (each.category=2)))-nb_erp_init)/nb_erp_init;
		if injuried {satisfaction<--1.0;}

	}



	//***************************  APPARENCE  ********************************************************
	aspect default {
		float haut;
		if inside{haut<-10#m;} 
		else {haut<-4#m;}
		if !is_protected {draw cylinder(2 #m, haut) color: my_color;}
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
	bool permeabilise<-false;
	bool jardin_pluie<-false;
	bool puits_infiltration<-false;
	
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
					if breaking_probability*water_pressure>0.1 {
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
		if permeabilise {
			permeability<-0.4;
			water_abs_max<-shape.area*15#cm;
		}
		if jardin_pluie {
			permeability<-permeability+0.2;
			water_abs_max<-water_abs_max+shape.area*10#cm;
		}
		if puits_infiltration {
				permeability<-permeability+0.3;
				water_abs_max<-water_abs_max+16#m3;
		}
		
		
		ask my_buildings {
			if vegetalise {
				myself.water_abs_max<-myself.water_abs_max+self.shape.area*35#cm;
				myself.permeability<-min([1,myself.permeability+0.9*self.shape.area/myself.shape.area]);
			}
		}
		
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
	
	 ask my_green_areas {
			if myself.plu_typ<3 {
				myself.permeability<-min([1,myself.permeability*(1-state)+0.90*state]);
				myself.water_abs_max<-myself.water_abs_max*(1-state)+shape.area*60#cm*state;
			}	
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
			float vol_river<-max([river_broad*sqrt(cell_area)*river_depth]);
			float prop_river<-water_volume/vol_river;
			water_river_height<-river_depth;
			if prop_river<1 {
				is_river_full<-false;
				vol_river<-water_volume;
				water_river_height<-river_depth*prop_river;
			}
			water_volume_no_river<-water_volume-vol_river;
			}
			water_height<-max([0,water_volume_no_river/cell_area]);
			water_altitude<-altitude -river_depth+water_river_height+ water_height;
			if water_height>1#m {is_critical<-true;}
	}
		
		


	//Action to flow the water 
	action flow {
		is_flowed<-false;
		do absorb_water;	
			int nb_neighbors<-length(neighbors);   
			list<cell> neighbour_cells_al <- neighbors where (each.already);
			list<cell> cell_to_flow;		
			prop<-0.9;
			volume_distrib<-water_volume*prop;
			float w_a<-water_altitude;
			ask neighbour_cells_al {	
	//			if (is_river_full and w_a > water_altitude and (w_a > (altitude+dyke_height-river_depth))) or (!is_river_full and w_a > water_altitude and (w_a > (altitude-river_depth))) {
			if (w_a > water_altitude and (w_a > (altitude+dyke_height-river_depth))) {	
					add self to:cell_to_flow;
						}
			}

					flow_cells <- remove_duplicates(cell_to_flow);
					float tot_den<-flow_cells sum_of (max([0,w_a-(each.altitude-each.river_depth)]));
					
					if (!empty(flow_cells) and tot_den>0) {			
						is_flowed<-true;

						ask flow_cells {
							prop_flow<-(w_a-(altitude+dyke_height-river_depth))/tot_den;
							volume_distrib_cell<-with_precision(myself.volume_distrib*prop_flow,4);
							water_volume <- water_volume + volume_distrib_cell;	
							do compute_water_altitude;
							
						} 
				 		water_volume <- water_volume - volume_distrib;
						do compute_water_altitude;
					
			} 
		already <- true;
		if is_sea {	water_height <- 0.0;}
}






	//Update the color of the cell
	action update_color {
		if (!is_sea) {
		color<-rgb(int(min([255,max([245 - 0.8 *altitude, 0])])), int(min([255,max([245 - 1.2 *altitude, 0])])), int(min([255,max([0,220 - 2 * altitude])])));
			
	//		color<-rgb(int(min([255,max([245 - 4 *altitude, 0])])), int(min([255,max([245 - 6 *altitude, 0])])), int(min([255,max([0,220 - 10 * altitude])])));
		}
	
		int val_water <- 0;

		
			/* 	if is_canal {
			color <- #mediumseagreen;
		}*/
		
		if (is_river) {//color<-#lightseagreen;	
	//	if (water_height>1#cm or water_river_height>1#cm) {
		if ( water_river_height>1#cm) {
			color <- #green;
		}
		
		}
		
		if (water_height>1#cm) {
		val_water <- max([0, min([200, int(200 * (1 - (water_height /2#m)))])]);
		color <- rgb([val_water, val_water, 255]);
		}
		if is_critical {color<-#red;}
		if (is_sea) {color<-#blue;}
		
	}

	aspect map {
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




grid button width:5 height:7 
{
	int id <- int(self);
	rgb bord_col<-#black;
	aspect normal {
		draw rectangle(shape.width * 0.8,shape.height * 0.8).contour + (shape.height * 0.01) color: bord_col;
		draw string(id) size:{shape.width,shape.height} color:#red;
		//draw image_file(images[id]) size:{shape.width,shape.height} ;
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
		//	species spe_riv;
			
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
		
		
	/* 	display map3D type: opengl background: #black draw_env: false {
			grid cell  triangulation:false refresh: true ;
			species cell  refresh: true aspect:map3D;				
		}
		
	*/	
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


experiment Tests type: batch keep_seed: true repeat:1 until:code_test_end {
	
	
}