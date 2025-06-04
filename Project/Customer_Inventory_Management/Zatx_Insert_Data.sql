-- -------------------------------------------------------------------------------------------------
/*********************** Script to insert record into the table ************** */ 
-- Created on : 30.04.2025
-- -------------------------------------------------------------------------------------------------


 USE Proj_Zatx;
/* ----- 1. Insert records with Company details  ---------------------------------*/
-- TRUNCATE  TABLE ci_company; -- This command deletes the data from the Table .
INSERT INTO ci_company
       ( Company_ID, Name )
VALUE ( "ZATX","ZATX Terminals" );
SELECT * FROM ci_company;

/*----- 2. Insert records about all the Inventory Operation details  -----------------------------*/
-- TRUNCATE TABLE ci_operation; -- This command should be executed only when you want to re-populate the table
INSERT INTO ci_operation
       ( Op_Code, Name, Amount )
VALUES
	  ( "FILLTANK" ,"Tank Filling Operation" ,15.00 ),
	  ( "LOADTRUCK","Truck Loading Operation",7.00  ),
	  ( "TRFTOTANK","Tank to tank Transfer"  ,12.00 ),
	  ( "FLUSHPIPE","Pipe Flushing operation",5.50  ),
	  ( "CLEANTANK","Tank Cleaning Operation",9.00  ),
	  ( "RENTAL"   ,"Tank Rental Charges"    ,15    );
SELECT * FROM ci_operation;

/*----- 3. Inserting records into the ci_customer Table -----------------------------*/
-- TRUNCATE TABLE ci_customer;
INSERT INTO ci_Customer
       (Name)
VALUES 
      ( "Dow Chemical Company" ),
      ( "ExxonMobil Chemical" ),
      ( "BASF" ),
      ( "Shell Chemicals" ),
      ( "Chevron Phillips Chemical" ),
      ( "LyondellBasell" ),
      ( "SABIC" ),
      ( "Ineos" ),
      ( "DuPont" ),
      ( "Air Liquide" ),
      ( "Linde" ),
      ( "Eastman Chemical Company" ),
      ( "Huntsman Corporation" ),
      ( "Solvay" ),
      ( "Sumitomo Chemical" );
      SELECT * FROM ci_customer;

/*----- 2. Insert records with Tank details -----------------------------*/
-- TRUNCATE TABLE ci_tank;
INSERT INTO ci_tank 
	   ( Tank_Type , Max_Capacity, Min_Threshold, Max_Threshold, Bal_Qty , Status)
VALUES
	   ( "S", 1000.00 , 100.00 , 950.00  , 0.00, "C" ),
	   ( "S", 1200.00 , 120.00 , 1140.00 , 0.00, "C" ),
	   ( "S", 1500.00 , 150.00 , 1425.00 , 0.00, "F" ),
	   ( "L", 10000.00, 1000.00, 9500.00 , 0.00, "F" ),
	   ( "L", 12000.00, 1200.00, 11400.00, 0.00, "F" ),
	   ( "L", 15000.00, 1500.00, 14250.00, 0.00, "F" ),
	   ( "L", 18000.00, 1800.00, 17100.00, 0.00, "F" ),
	   ( "M", 5000.00 , 500.00 , 4750.00 , 0.00, "F" ),
	   ( "M", 6000.00 , 600.00 , 5700.00 , 0.00, "F" ),
	   ( "M", 7500.00 , 750.00 , 7125.00 , 0.00, "F" ),
	   ( "S", 2000.00 , 200.00 , 950.00  , 0.00, "C" );
SELECT * FROM ci_tank;






