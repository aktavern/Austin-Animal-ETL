# Austin-Animal-ETL
This repo contains the code to extract data from data.austintexas.gov regarding the Austin Animal Center intakes and outcomes, transform that data as necessary, and load it into a Postgres database. 

# Extract 
We used 2 sources of data:
<ul>
  <li><a href="https://data.austintexas.gov/Health-and-Community-Services/Austin-Animal-Center-Intakes/wter-evkm">Intake Data</a></li>
  <li><a href="https://data.austintexas.gov/Health-and-Community-Services/Austin-Animal-Center-Outcomes/9t4d-g238">Outcome Data</a></li>
</ul>

We downloaded the CSVs and stored them in the Resources file. We used Pandas and Jupyter Notebook to get the CSV data. 

# Transform
From the intake and outcome files, we dropped unnessary columns so that we displayed only necessary and relevant data:

```
intake_df = intake[['Animal ID','Name','DateTime','Intake Type','Intake Condition','Animal Type','Age upon Intake','Breed','Color']]
```
  
```
outcomes_df= outcomes [['Animal ID','Name','DateTime','Outcome Type','Age upon Outcome']]
```
  
We also renamed the columns to make it easier to use in PostgreSQL:

```
  intake_df = intake_df.rename(columns ={'Animal ID': 'id',
             'Name': 'intake_name',
             'DateTime': 'intake_time',
             'Intake Type': 'intake_type',
             'Intake Condition': 'intake_condition',
             'Animal Type': 'animal_type',
             'Age upon Intake' :'intake_age',
             'Breed': 'breed',
             'Color': 'color'
             })
  ```
  
```
    outcomes_df = outcomes_df.rename(columns ={'Animal ID': 'id',
                                         'Name' : 'outcome_name',
                                         'DateTime': 'outcome_date',
					 'Outcome Type': 'outcome_type',
                                         'Age upon Outcome':'outcome_age'})
 ```
 
 # Load
 We used PostgreSQL, as the data was structured and could be joined together. We used the following queries to create the necessary database and tables:
 
 ```
 -- Create the database
 CREATE DATABASE austin_animal_center;
 
 --- Create intakes table
 CREATE TABLE intakes(id varchar(30),
             intake_name varchar,
             intake_date timestamp,
              intake_type varchar,
              intake_condition varchar,
              animal_type varchar,
             intake_age varchar,
             breed varchar,
             color varchar)
	     
--- Create outcomes table			 
CREATE TABLE outcomes(id varchar(30),
                       outcome_name varchar,
                       outcome_date timestamp,
		       outcome_type varchar,
                       outcome_age varchar)
 
 ```
Because id could appear multiple times in the table, it was not a suitable primary key. Consequently, we did not have a primary key for our tables.

Instead, the following query can be used to join the data as needed:

```pd.read_sql_query('select distinct i.intake_time,\
     (select min(outcome_date) from outcomes o where o.id = i.id and outcome_date >= i.intake_time) as outcome_date,\
    i.id, \
    i.intake_name,\
    (select min(outcome_name) from outcomes o where o.id = i.id) as outcome_name,\
    i.intake_type,\
    i.intake_condition,\
    i.animal_type,\
    i.intake_age,\
    (select min(o.outcome_age) from outcomes o where o.id = i.id) as outcome_age,\
    i.breed,\
    i.color,\
    (select min(outcome_type) from outcomes o where o.id = i.id) as outcome_type\
    from intakes i', con=engine)
   ```
 
Using sqlalchemy, we loaded the transformed data into the appropriate tables:
```
intake_df.to_sql(name = 'intakes', con = engine, if_exists='append', index =False)
outcomes_df.to_sql(name = 'outcomes' , con = engine, if_exists ='append', index = False)
```
