/**
* Name: Rouentemplate
* Author: administrateur
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model Rouentemplate

global {
	string dataset_path <- "../../includes/city_environment/";
	
	csv_file Age__CoupleTableau_10_csv_file <- csv_file(dataset_path + "statistics/Age & Couple-Tableau 1.csv");

	file f_AC <- file(dataset_path + "statistics/Age & Couple-Tableau 1.csv");	
	file f_AS <- file(dataset_path + "statistics/Age & Sexe-Tableau 1.csv");
	file f_ASCSP <- file(dataset_path + "statistics/Age & Sexe & CSP-Tableau 1.csv");
	file f_IRIS <- file(dataset_path + "statistics/LaCiotatIris.csv");

	file iris_shp <- shape_file(dataset_path + "iris_lambert93.shp");


	file buildings_shape_file <- shape_file(dataset_path+"buildings_lambert93.shp");
	file buildings_shape_file_capacity <- shape_file(dataset_path + "buildings_capacity.shp");

	
	//name of the property that contains the id of the census spatial areas in the shapefile
	string stringOfCensusIdInShapefile <- "CODE_IRIS";

	//name of the property that contains the id of the census spatial areas in the csv file (and population)
	string stringOfCensusIdInCSVfile <- "iris";

	geometry shape <- envelope(iris_shp);

	list<string> tranches_age <- ["Moins de 5 ans", "5 à 9 ans", "10 à 14 ans", "15 à 19 ans", "20 à 24 ans", 
				  				"25 à 29 ans", "30 à 34 ans", "35 à 39 ans", "40 à 44 ans", "45 à 49 ans", 
								"50 à 54 ans", "55 à 59 ans", "60 à 64 ans", "65 à 69 ans", "70 à 74 ans", "75 à 79 ans", 
								"80 à 84 ans", "85 à 89 ans", "90 à 94 ans", "95 à 99 ans", "100 ans ou plus"];

	list<string> list_CSP <- ["Agriculteurs exploitants", "Artisans. commerçants. chefs d'entreprise", 
							"Cadres et professions intellectuelles supérieures", "Professions intermédiaires", 
							"Employés", "Ouvriers", "Retraités", "Autres personnes sans activité professionnelle"];

	
	init {		
		create iris from: iris_shp  with: [code_iris::string(read('CODE_IRIS'))] ;
		create Building from: buildings_shape_file {
			if flats > 1 {
				capacity <- flats * 5;
			} else {
				if type in ["house", "yes", "residential", "apartments"] {
					capacity <- 5;
				} else {
					capacity <- -1;
				}
			}
		}
		
		save Building type: shp to: buildings_shape_file_capacity.path attributes: ["capacity"::capacity];
		
		ask Building {do die;}
		create Building from:buildings_shape_file_capacity;
		
		gen_population_generator pop_gen;
		pop_gen <- pop_gen with_generation_algo "IS";  //"Sample";//"IS";

		pop_gen <- add_census_file(pop_gen, f_AC.path, "ContingencyTable", ";", 1, 1); 
		pop_gen <- add_census_file(pop_gen, f_ASCSP.path, "ContingencyTable", ";", 2, 1);
		pop_gen <- add_census_file(pop_gen, f_AS.path, "ContingencyTable", ";", 1, 1);
		pop_gen <- add_census_file(pop_gen, f_IRIS.path, "ContingencyTable", ",", 1, 1);			
		// --------------------------
		// Setup "AGE" attribute: INDIVIDUAL 
		// --------------------------	
		int nb_people;
		loop i from: 0 to: matrix(f_IRIS).rows -1{
			nb_people <- nb_people + int(matrix(f_IRIS)[1,i] );
		}
		pop_gen <- pop_gen add_attribute("Age", gen_range, tranches_age);
		
		map mapper1 <- [
			["15 à 19 ans"]::["15 à 19 ans"], ["20 à 24 ans"]::["20 à 24 ans"], ["25 à 39 ans"]::["25 à 29 ans", "30 à 34 ans", "35 à 39 ans"],
			["40 à 54 ans"]::["40 à 44 ans", "45 à 49 ans", "50 à 54 ans"], ["55 à 64 ans"]::["55 à 59 ans", "60 à 64 ans"],
			["65 à 79 ans"]::["65 à 69 ans", "70 à 74 ans", "75 à 79 ans"], ["80 ans ou plus"]::["80 à 84 ans", "85 à 89 ans", "90 à 94 ans", "95 à 99 ans", "100 ans ou plus"]
		];
		pop_gen <- pop_gen add_mapper("Age", gen_range, mapper1);					
				
		map mapper2 <- [
			["15 à 19 ans"]::["15 à 19 ans"], ["20 à 24 ans"]::["20 à 24 ans"], ["25 à 39 ans"]::["25 à 29 ans","30 à 34 ans","35 à 39 ans"],
			["40 à 54 ans"]::["40 à 44 ans","45 à 49 ans","50 à 54 ans"], ["55 à 64 ans"]::["55 à 59 ans", "60 à 64 ans"],
			["65 ans ou plus"]::["65 à 69 ans","70 à 74 ans","75 à 79 ans","80 à 84 ans","85 à 89 ans","90 à 94 ans","95 à 99 ans","100 ans ou plus"]
		];
		pop_gen <- pop_gen add_mapper("Age", gen_range, mapper2);


		// -------------------------
		// Setup "CSP" attribute: INDIVIDUAL
		// -------------------------

		pop_gen <- pop_gen add_attribute("CSP", string, list_CSP);
	

		// --------------------------
		// Setup "COUPLE" attribute: INDIVIDUAL
		// --------------------------				
				
		pop_gen <- pop_gen add_attribute("Couple", string, ["Vivant en couple", "Ne vivant pas en couple"]);
				
				
		// -------------------------
		// Setup "SEXE" attribute: INDIVIDUAL
		// -------------------------
		
		pop_gen <- pop_gen add_attribute("Sexe", string, ["Hommes", "Femmes"]);


		// -------------------------
		// Setup "IRIS" attribute: INDIVIDUAL
		// -------------------------
 
		
		list<string> liste_iris <- [
			"130280114", "130280105","130280106","130280112","130280104","130280101","130280103","130280102"];
			
		pop_gen <- pop_gen add_attribute("iris", string, liste_iris, "P16_POP", int);  

 
		// -------------------------
		// Spatialization 
		// -------------------------
	//	pop_gen <- pop_gen localize_on_geometries(iris_shp.path);
		pop_gen <- pop_gen localize_on_geometries(buildings_shape_file_capacity.path);
		
		
		pop_gen <- pop_gen localize_on_census(iris_shp.path);
		pop_gen <- pop_gen add_spatial_match(stringOfCensusIdInCSVfile,stringOfCensusIdInShapefile);
		pop_gen <- pop_gen add_capacity_constraint ("capacity");
		// -------------------------			
		
		create people from: pop_gen  number: nb_people	;
		save people to:dataset_path + "population.shp" type: shp attributes:["Age"::Age, "Sexe"::Sexe,"CSP"::CSP, "Couple"::Couple];

	}
}

species people {
	int Age;
	string Sexe;
	string iris;
	string Couple;
	string CSP;

	aspect default { 
		draw circle(4) color: #red border: #black;
	}
}

species iris {
	string code_iris;
	rgb color <- rnd_color(255);
	aspect default {
		draw shape color:color  border: #black;
	}
}

species Building {
	int capacity;
	int flats;
	string type;
	int levels;
	float height;
	aspect default {
		draw shape color:#gray  border: #black;
	}
}

experiment generate_pop type: gui {
	output {
		display map  type: opengl {
			species iris;
			species Building;
			species people;
		}
		
	}
}
