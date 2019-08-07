create table intakes( id varchar(30) PRIMARY KEY,
             intake_name varchar,
             intake_time timestamp,
              intake_type varchar,
              intake_condition varchar,
              animal_type varchar,
             intake_age varchar,
             breed varchar,
             color varchar)
			 
create table outcomes (id varchar(30) PRIMARY KEY,
                       outcome_name varchar,
                       outcome_date timestamp,
                       outcome_age varchar,
					  FOREIGN KEY(id) references intakes(id))			 