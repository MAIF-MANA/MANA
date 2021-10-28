/**
* Name: testRadar
* Based on the internal empty template. 
* Author: Patrick Taillandier
* Tags: 
*/
model testRadar

global {
	float cycle_eau <- 0.0 update: rnd(5.0);
	float satisfaction_crit <- 0.0 update: rnd(5.0);
	float biodiversite_crit <- 0.0 update: rnd(5.0);
	list<geometry> axis <- define_axis();
	list<float> val_min <- [0.0, 0.0, 0.0];
	list<float> val_max <- [5.0, 5.0, 5.0];
	list<string> axis_label <- ["Cycle de l'eau", "Satisfaction de la population", "Biodiversité"];
	float marge <- 0.1;
	
	list<geometry> define_axis {
		list<geometry> gs;
		float angle_ref <- 360 / length(axis_label);
		float marge_dist <- world.shape.width * marge;
		loop i from: 0 to: length(axis_label) - 1 {
			geometry g <- (line({0, world.shape.height / 2}, {0, marge_dist}) rotated_by (i * angle_ref));
			g <- g at_location (g.location + world.location - first(g.points));
			gs << g;
		}
		return gs;
	}

	list<point> define_surface (list<float> values) {
		list<point> points;
		loop i from: 0 to: length(values) - 1 {
			float prop <- (values[i] - val_min[i]) / (val_max[i] - val_min[i]);
			points << first(axis[i].points) + (last(axis[i].points) - first(axis[i].points)) * prop;
		}
		return points;
	}

}

experiment main {
	output {
		display map type: opengl {
			graphics "radars axis" refresh: false{
				loop i from: 0 to: length(axis) -1 {
					geometry a <- axis[i];
					draw a + 0.1 color: #black end_arrow: 2.0;
					point pt <- first(axis[i].points) + (last(axis[i].points) - first(axis[i].points)) * 1.1;
					draw axis_label[i]  at: pt anchor: #center font: font("Helvetica", 24, #bold) color: #black;
					
				}
			}

			graphics "radars surface" transparency: 0.5 {
				list<float> values <- [cycle_eau, satisfaction_crit, biodiversite_crit];
				list<point> points <- world.define_surface(values);
				geometry surface <- polygon(points);
				draw surface color: #yellow border: #orange;
				loop i from: 0 to: length(axis) -1 {
					float angle <- (first(axis[i].points) towards last(axis[i].points)) ;
					if angle > 90 or angle < - 90{
						angle <- angle - 180;
					}
					float dist <- 1.0;
					point shift_pt <- {cos(angle + 90) * dist, sin(angle + 90) * dist};	
		
					point pt <- points[i] + shift_pt;
					
					draw string(values[i] with_precision 1.0)  at: pt anchor: #center font: font("Helvetica", 24, #bold) color: #black;
					
				}
			}

		}

	}

}