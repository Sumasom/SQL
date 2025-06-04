use Proj_zatx;

DROP PROCEDURE IF EXISTS sp_add_new_contract;

 -- -------------------------------------------------------------------------------------------------
 /*
Creating a procedure sp_add_new_contract to create new contract between a customer and ZATX 
Validations :
    o To check customer and tank existence
    o Ensure tank is available (not already contracted)
    o Verify start date is within allowed range
After the validation are done, end date is calculated based on duration and ci_tank Master Table is
updated with status (C)Contracted
Created on : 30.04.2025 
*/
-- -------------------------------------------------------------------------------------------------
DELIMITER $$
	CREATE PROCEDURE sp_add_new_contract(
									 IN v_cust_id    INT,
									 IN v_tank_id    INT,
									 IN v_start_date DATE,
									 IN v_duration   INT,
									 OUT out_message VARCHAR(150)
									 )
	BEGIN
	/* local variables of the store procedure */
		DECLARE l_counter  INT ;
		DECLARE l_end_date DATE;
		DECLARE l_status   VARCHAR(1);
       --  DECLARE l_bal_qty  DECIMAL(15,2);
       -- Not used  DECLARE l_max_threshold DECIMAL(15,2);
    /* This block is executed i.e The transaction is rolled back when any SQL exception happens */
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			ROLLBACK; 
		END;
    
    /* Start a new transaction to ensure data integrity of the operations */
		START TRANSACTION;
     
 
    -- Start of input validation
	-- CHECK 1 : Validating existing Customer
		SELECT count(*)Cust_ID INTO l_counter 
		FROM ci_customer
		WHERE Cust_ID = v_cust_id;
    
		IF l_counter = 0 THEN
	   -- ROLLBACK;
			SET out_message  = 'Transaction rolled back : Invalid Customer';
			SIGNAL SQLSTATE '45000' -- Display customized error message on occurance of SQL Exception 
			SET MESSAGE_TEXT = out_message;
		ELSE SET l_counter = 0; -- If its an active customer , counter is 1 and during the next validation for tank_Id , counter is stil 1 and incorrect Tankid is not captured , hence reste to 0
		END IF;
    
    -- CHECK 2 : Validating Start Date is within 2024-11-01 and 2025-03-31
		IF((v_start_date < "2024-11-01") OR (v_start_date > "2025-03-31"))THEN
	  -- ROLLBACK;
	        SET out_message  = 'Transaction rolled back : Start Date is not within the valid range';
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = out_message;
	    END IF;
    
    
    -- Check 3 : Validating existing Tank_ID
		-- SELECT Bal_Qty,Max_Threshold INTO l_bal_qty,l_max_threshold FROM ci_tank
        -- WHERE Tank_ID = v_tank_ID;
        
        SELECT count(*)Tank_ID,Status  INTO l_counter,l_status
		FROM ci_tank
		WHERE Tank_ID = v_tank_id 
        GROUP BY Status;
		
		IF l_counter = 0 THEN
	   -- ROLLBACK;
		SET out_message = 'Transaction Rolled Back: Invalid Tank Number';
	    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = out_message;
        
		ELSEIF (l_counter = 1 AND l_status = 'C') THEN
        -- ROLLBACK;
        SET out_message  = 'Transaction rolled back : Tank is already contracted';
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = out_message;
        
	 /*If a valid tank_id exists and it is FREE(F),then insert the record into the contract Table ,
	 update the Status in the ci_contarct table as contract  is(A)ACTIVE and the ci_Tank Master Table 
     Status as (C)CONTRACTED .*/
        ELSEIF(l_counter = 1 AND l_status = 'F') THEN
			SET l_end_date = DATE_ADD(v_start_Date,interval v_duration YEAR);
			SET l_status = "A";
       
		-- SELECT v_cust_id , v_tank_id , v_start_date , v_duration , l_end_date , l_status;
		INSERT INTO ci_contract(
				Cust_ID , Tank_ID , Start_Date , Duration , End_Date,Status
	    )
		VALUES (
				v_cust_id , v_tank_id , v_start_date , v_duration , l_end_date , l_status
	    );
		
	    SET out_message = concat( "A new record is inserted for Customer: ", v_cust_Id,",Tank_ID : ",v_tank_id,"  and transaction is committed successfully");
	    UPDATE ci_tank SET status = "C" -- contracted
	    WHERE Tank_id = v_tank_id;
       
	    COMMIT ;-- End of Transaction
		END IF ;  
	END $$
DELIMITER ; -- End of Procedure 


CALL sp_add_new_contract(5004,9004,'2024-12-25',1,@new_record_msg);
CALL sp_add_new_contract(5001,9007,'2024-12-30',1,@new_record_msg);
CALL sp_add_new_contract(5012,9006,'2025-01-18',1,@new_record_msg);
CALL sp_add_new_contract(5002,9002,'2025-02-02',1,@new_record_msg);
CALL sp_add_new_contract(5009,9001,'2025-02-14',1,@new_record_msg);
SELECT @new_record_msg;

SELECT * FROM ci_tank;