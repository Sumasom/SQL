USE Proj_Zatx;

DROP PROCEDURE IF EXISTS sp_truck_entry_weight;
-- -------------------------------------------------------------------------------------------------
/*
Creating a procedure sp_truck_entry_weight to record the initial entry of truck for loading without the product
(STAGE 1 of Truck Loading)
Validations :
	o Verify active contract exists, Validate transaction date
	o Check truck number is provided
	o Ensure entry weight is greater than zero
	o Prevent duplicate pending entries for same truck
   
After the validation , record is inserted into ci_truckload Table with entry weight 
(exit weight and net weight is null)
Created on : 30.04.2025
*/
-- -------------------------------------------------------------------------------------------------

DELIMITER $$
CREATE PROCEDURE sp_truck_entry_weight(
                                       IN  v_tank_id    INT,
                                       IN  v_cust_id    INT,
                                       IN  v_txn_date   DATE,                                       
                                       IN  v_ent_wt     DECIMAL(15,2),
                                       IN  v_truck_no   VARCHAR(15),
                                       OUT out_message VARCHAR(100)
									   )
BEGIN
    /* local variables of the store procedure*/
	
    DECLARE l_start_date    DATE;
    DECLARE l_status        VARCHAR(1);
    DECLARE v_max_threshold DECIMAL(15,2);
    DECLARE v_min_threshold DECIMAL(15,2);
    DECLARE l_exit_wt       DECIMAL(15,2);
    DECLARE l_entry_wt      DECIMAL(15,2);
    
    /* This block is executed i.e The transaction is rolled back when any SQL exception happens*/
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
       BEGIN
        ROLLBACK;
       END;
    
    /* Start a new transaction to ensure data integrity of the operations */
    START TRANSACTION;   
    
     -- Start of input validation
	 -- Check 1: Verify active contract exists for the tank and customer 
     SELECT status into l_status 
	 FROM  ci_contract
	 WHERE Tank_Id = v_tank_Id and Cust_id = v_cust_id;
	    
	 IF l_status = 'C' OR l_status is NULL THEN
		SET out_message  = concat("Transaction rolled back : No Active Contract Exists for Tank : ",v_tank_id , " and Customer:" , v_cust_id);
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message; 
	 END IF;
        
    -- Check 2 : Validate the pending entry for the same truck
    
	 SELECT Truck_entry_wt ,Truck_exit_wt INTO l_entry_wt,l_exit_wt FROM ci_truckload
	 WHERE Truck_No = v_truck_no;
      
	 -- For the same truck_no  check if there was entry and no exit , if yes print Error.
	 IF EXISTS (SELECT Truck_NO FROM ci_truckload WHERE l_entry_wt is NOT NULL AND l_exit_wt is NULL) 
	 THEN
        SET out_message  = "The truck is already in yard waiting to be filled ";
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message ;
	 END IF ;
       
     
   -- Check 3: Validate transaction date is after contract start date and not in future 
     IF (v_txn_date < l_start_date) OR (v_txn_date > "2025-03-31")THEN 
		SET out_message  = "Transaction rolled back : Invalid Transaction Date";
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message;
	 END IF ;
        
	-- Check 4: Validate entry weight is > 0
	SELECT Min_Threshold,Max_Threshold INTO v_min_threshold,v_max_threshold
    FROM ci_tank
    WHERE Tank_ID = v_tank_id;
    
    -- If entry_weight is <= 0 then display error , Adding (v_ent_wt < v_min_threshold) check because 
	-- even if a value of 1 is entered for entry SQL accepts which is wrong 
    -- since entry_weight cannot be 1  
    IF (v_ent_wt <= 0) OR (v_ent_wt < v_min_threshold )
	THEN
		SET out_message  ="Transaction rolled back : Entry Weight of the Truck is too low";
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message;
	-- If validations are complete , then insert the record into the ci_truckload Table with ony entry
    -- weight , exit and net null will take their default value i.e NULL
	ELSE 
	    INSERT INTO ci_truckload
		        ( Tank_ID, Cust_ID, Txn_date, Truck_No, Truck_entry_wt, Op_Code ) 
		VALUES  ( v_tank_id, v_cust_id, v_txn_date, v_truck_no, v_ent_wt, "LOADTRUCK");
        COMMIT; -- End of the transaction 
	END IF;
    
END $$                       
DELIMITER ; -- End of Store Procedure .



-- -- Inserting 5 Truck Entry Records.
CALL sp_truck_entry_weight(9004,5004,"2024-12-30",10000.00,"KA6035",@truck_entry_msg);
CALL sp_truck_entry_weight(9007,5001,"2025-01-05",10000.00,"KA2025",@truck_entry_msg);
CALL sp_truck_entry_weight(9006,5012,"2025-02-18",15000.00,"TS6125",@truck_entry_msg);
CALL sp_truck_entry_weight(9002,5002,"2025-02-07", 5000.00,"TN9162",@truck_entry_msg);
CALL sp_truck_entry_weight(9001,5009,"2025-02-22", 5000.00,"KL9099",@truck_entry_msg);
CALL sp_truck_entry_weight(9001,5009,"2025-02-22", 5000.00,"X29400",@truck_entry_msg);
SELECT @truck_entry_msg;



