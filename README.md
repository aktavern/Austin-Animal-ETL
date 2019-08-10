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
 
 We realized that 'id' was not unique between intake or outcome data, because the same animal could visit the shelter multiple times. When we merged the data with pandas, we consistently ran into an issue where the dates were not correct, and there was not an easy way to only get the dates that were relevant for that animal. 
 
 We came up with the following query to join the data in sql:
 
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
   
 However, this took too much time to process, given that there were over 100k unique rows per file. 
 
 We decided to only use 2019 data as a result. We completed the following transformations:
 
 1. We converted the time data to a datetime object, then extracted only the date. From there, we looked for only 2019 data:
 
 ``` # Convert intake dates to datetime format and get only the date
intake_df['intake_date'] = pd.to_datetime(intake_df['intake_date'])
intake_df['only_date'] = [d.date() for d in intake_df['intake_date']]
# Convert only date to string
intake_df['only_date'] = intake_df['only_date'].astype('str')
# Look for animals that have been in the shelter this year 
intake_2019 = intake_df.loc[intake_df['only_date'] >= '2019-01-01']
intake_2019

# Convert outcome dates to datetime formate and get only the date
outcomes_df['outcome_date'] = pd.to_datetime(outcomes_df['outcome_date'])
outcomes_df['only_date'] = [d.date() for d in outcomes_df['outcome_date']]
#Convert only date to string
outcomes_df['only_date'] = outcomes_df['only_date'].astype('str')
# Look for animals that have left the shelter this year 
outcomes_2019 = outcomes_df.loc[outcomes_df['only_date'] >= '2019-01-01']
outcomes_2019
```

2. We then selected only the columns we cared about so that the data could be loaded into PostgreSQL:

``` 
intake_2019 = intake_2019[['id','intake_name','intake_date','intake_type','intake_condition','animal_type','intake_age','breed','color']]
outcomes_2019 = outcomes_2019[['id','outcome_name','outcome_date','outcome_type','outcome_age']]
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
		       
--- Create 2019 intakes table 

CREATE TABLE intakes_2019(id varchar(30),
             intake_name varchar,
             intake_date timestamp,
              intake_type varchar,
              intake_condition varchar,
              animal_type varchar,
             intake_age varchar,
             breed varchar,
             color varchar);

--- Create 2019 outcomes table
CREATE TABLE outcomes_2019(id varchar(30),
                       outcome_name varchar,
                       outcome_date timestamp,
					  outcome_type varchar,
                       outcome_age varchar)
 
 ```
 
Because id could appear multiple times in the table, it was not a suitable primary key. Consequently, we did not have a primary key for our tables.

Using sqlalchemy, we loaded the transformed data into the appropriate tables:
```
intake_df.to_sql(name = 'intakes', con = engine, if_exists='append', index =False)
outcomes_df.to_sql(name = 'outcomes' , con = engine, if_exists ='append', index = False)
intake_2019.to_sql(name='intakes_2019', con=engine,if_exists='append',index=False)
outcomes_2019.to_sql(name='outcomes_2019', con=engine,if_exists='append',index=False)
```

We joined the 2019 data together using this adjusted query using pandas: 

```
joined_data = pd.read_sql_query('select distinct i.intake_date,\
     (select min(outcome_date) from outcomes_2019 o where o.id = i.id and outcome_date >= i.intake_date) as outcome_date,\
    i.id, \
    i.intake_name,\
    (select min(outcome_name) from outcomes_2019 o where o.id = i.id) as outcome_name,\
    i.intake_type,\
    i.intake_condition,\
    i.animal_type,\
    i.intake_age,\
    (select min(o.outcome_age) from outcomes_2019 o where o.id = i.id) as outcome_age,\
    i.breed,\
    i.color,\
    (select min(outcome_type) from outcomes_2019 o where o.id = i.id) as outcome_type\
    from \
intakes_2019 i', con=engine)
```

This successfully combined the data in a reasonable timeframe. We were able to confirm with a sample id that the data was accurate within our notebook. 

# Conclusion
The process of transforming the date information, searching for data within a particular year, and query joining that data could work for additional years. However, we came to the conclusion that when designing an ETL, it is important to create unique ids for the data. This makes joining much more reliable and easier to complete in SQL. Having a dataset with no primary key is not a best practice and requires additional workarounds, and is consequently not ideal for an ETL process. 
