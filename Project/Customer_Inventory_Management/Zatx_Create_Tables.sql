-- -------------------------------------------------------------------------------------------------
-- This Database is created for the ZATX Customer Inventory Management PROJECT 
-- Convention ci_* indicates Customer Inventory
-- Created on : 30.04.2025
-- -------------------------------------------------------------------------------------------------


/* ------------------------  Creating PROJ_ZATX database ------------------------------------------- */
 -- DROP DATABASE Proj_Zatx;
 CREATE DATABASE Proj_Zatx; 
 USE Proj_Zatx;

/* ------------------------------------------------------------------------------------------------- */

/* --------------------------------- ** MASTER TABLES ** --------------------------------------------*/
 
-- Table 1 :  ci_company Master table that holds information about the ZATX company
DROP TABLE  IF EXISTS ci_company;
CREATE TABLE IF NOT EXISTS ci_company (
									   Company_ID VARCHAR(10) PRIMARY KEY,
									   Name       VARCHAR(45) NOT NULL
									  );
-- --------------------------------------------------------------------------------------------------

-- Table 2 :ci_operation Master Table holds information about the operation code and their associated charges per tonne
DROP TABLE IF EXISTS ci_operation;
CREATE TABLE IF NOT EXISTS ci_operation(
										Op_Code VARCHAR(25) PRIMARY KEY,
										Name    VARCHAR(45) NOT NULL ,
										Amount  DECIMAL(15,2),
                                         
										CHECK ( Amount > 0.0 )
										);

-- --------------------------------------------------------------------------------------------------
-- Table 3 : Ci_customer Master table to store details of the ZATX customer 
DROP TABLE IF EXISTS ci_customer;
CREATE TABLE IF NOT EXISTS ci_customer(
									   Cust_ID  INT AUTO_INCREMENT ,
									   Name     VARCHAR(45) NOT NULL ,                                        
                                       PRIMARY KEY(Cust_ID)
									   );
ALTER TABLE ci_customer AUTO_INCREMENT = 5001;
-- --------------------------------------------------------------------------------------------------

-- Table 4 : ci_tank Master table to store all the details about the TANK
DROP TABLE IF EXISTS ci_tank;
CREATE TABLE IF NOT EXISTS ci_tank (
									Tank_ID       INT AUTO_INCREMENT ,
                                    Tank_Type     VARCHAR(1),-- L/M/S--> (Large,Medium,Small)
                                    Max_Threshold DECIMAL(15,2),
                                    Min_Threshold DECIMAL(15,2),
                                    Max_Capacity  DECIMAL(15,2),
                                    Bal_Qty       DECIMAL(15,2),
                                    Status        VARCHAR(1),-- Values F(Free) and C(Contracted)
                                    PRIMARY KEY(Tank_ID)
                                    );
ALTER TABLE ci_tank AUTO_INCREMENT = 9001;
-- --------------------------------------------------------------------------------------------------


/* ----------------------------------- ** TRANSACTION TABLES ** -------------------------------------*/

-- TABLE 1 : Stores the details of agreement  between customer and the company via an agreement
DROP TABLE IF EXISTS ci_contract;
CREATE TABLE IF NOT EXISTS ci_contract(
									   Contract_ID INT AUTO_INCREMENT ,
                                       Cust_ID     INT,
                                       Tank_ID     INT,
                                       Duration    INT,
                                       Start_Date  DATE,
                                       End_Date    DATE,
									   Status      VARCHAR(1) DEFAULT "C",-- Accepted values A(Active),C(Closed)
                                       
                                       PRIMARY KEY (Contract_ID),
                                       FOREIGN KEY (Cust_ID) REFERENCES ci_customer(Cust_ID),
                                       FOREIGN KEY (Tank_ID) REFERENCES ci_tank(Tank_ID)
                                       -- CHECK (Start_Date >= "2024-11-01" and Start_Date < "2025-03-31")	
									   );
ALTER TABLE ci_contract AUTO_INCREMENT = 7001;
-- --------------------------------------------------------------------------------------------------


-- TABLE 2: Holds the details of the Tank into which product is filled from the ship/vessel.
DROP TABLE IF EXISTS ci_tankfill;
CREATE TABLE IF NOT EXISTS ci_tankfill (
										Txn_ID   INT AUTO_INCREMENT,
										Tank_ID  INT,
										Cust_ID  INT,
										Ship_No  VARCHAR(15) NULL,
										Op_Code  VARCHAR(15)NOT NULL,
										Status   VARCHAR(1) NOT NULL DEFAULT "A",
                                        Txn_Date DATE NOT NULL,
										Qty      DECIMAL(15,2) ,
										  
										PRIMARY KEY (Txn_ID),
										FOREIGN KEY (Tank_ID) REFERENCES ci_tank(Tank_ID),
										FOREIGN KEY (Cust_ID) REFERENCES ci_customer(Cust_ID),
										CHECK (Qty > 0.00)
									  );

-- --------------------------------------------------------------------------------------------------
/* Table 3: To store details about the Truck Loading operations. 
	        Captures the container weight during entry and exit from the yard. */

DROP TABLE IF EXISTS ci_truckload;
CREATE TABLE IF NOT EXISTS ci_truckload(
										Txn_ID         INT AUTO_INCREMENT,
										Tank_ID        INT,
										Cust_ID        INT,
										Txn_date       DATE NOT NULL,
										Truck_entry_wt DECIMAL(15,2) NULL,
										Truck_exit_wt  DECIMAL(15,2) NULL,	
										Net_wt		   DECIMAL(15,2) NULL,
										Op_Code        VARCHAR(15) NOT NULL,
										Truck_No	   VARCHAR(15) NOT NULL,
										Status         VARCHAR(1)  NOT NULL DEFAULT "A",
										PRIMARY KEY (Txn_ID),
										FOREIGN KEY (Tank_ID) REFERENCES ci_tank(Tank_ID),
										FOREIGN KEY (Cust_ID) REFERENCES ci_customer(Cust_ID)
									   );
-- --------------------------------------------------------------------------------------------------
/* Table 4 : Captures all the Transaction Logs.It captures the summary details of the every successful transaction of Tankfill
             and TruckLoad .Triggers are used to populate this table */
             
DROP TABLE IF EXISTS ci_translog;
CREATE TABLE IF NOT EXISTS ci_translog(
										Txn_ID   INT AUTO_INCREMENT,
                                        Cust_ID  INT,
										Op_code	 VARCHAR(25) NOT NULL ,	
										Txn_Date DATE	,	
										Txn_qty	 DECIMAL(15,2), 
										CHECK (Txn_qty > 0.00),
                                        PRIMARY KEY(Txn_ID)
										);                        
-- --------------------------------------------------------------------------------------------------

