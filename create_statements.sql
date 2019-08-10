CREATE DATABASE austin_animal_center;

CREATE TABLE intakes(id varchar(30),
             intake_name varchar,
             intake_date timestamp,
              intake_type varchar,
              intake_condition varchar,
              animal_type varchar,
             intake_age varchar,
             breed varchar,
             color varchar);
			 
CREATE TABLE outcomes(id varchar(30),
                       outcome_name varchar,
                       outcome_date timestamp,
					  outcome_type varchar,
                       outcome_age varchar)