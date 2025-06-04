USE Proj_Zatx;

DROP PROCEDURE IF EXISTS sp_fill_tank; -- Dropping the procedure if it already exists 

-- -------------------------------------------------------------------------------------------------
/*
Creating a procedure sp_fill_tank to record Tank filling from the vessel
Validations :
    o Verify active contract exists for customer and tank
    o Validate transaction date,ship no 
    o Check if quantity doesn't exceed tank threshold
   
After the validations are successfuly completed , record is inserted into ci_tankfill and an AFTER 
INSERT  trigger auotmatically updates the tank balance  in the ci_tank Master Table which is the 
sum of qty  already available in the tank and qty newly filled into the tank from the vessel
-- Created on : 30.04.2025
*/
-- -------------------------------------------------------------------------------------------------

DELIMITER $$
CREATE PROCEDURE sp_fill_tank(
                              IN  v_tank_id    INT,
                              IN  v_cust_ID    INT,
							  IN  v_txn_date   DATE,
							  IN  v_ship_no    VARCHAR(45),
							  IN  v_qty        DECIMAL(15,2),
							  OUT out_message  VARCHAR(300)
							 )
BEGIN
    /* local variables of the store procedure*/
	DECLARE l_counter            INT;   
	DECLARE l_start_date         DATE;
    DECLARE l_op_code            VARCHAR(25);
    DECLARE l_tank_status        VARCHAR(1);
    DECLARE l_status             VARCHAR(1);
    DECLARE l_tank_balance_qty   DECIMAL(15,2);
    DECLARE l_tank_max_threshold DECIMAL(15,2);
    /* This block is executed i.e The transaction is rolled back when any SQL exception happens*/
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
	  ROLLBACK;
    END;
    
    /* Start a new transaction to ensure data integrity of the operations */
    START TRANSACTION;
    
	-- Start of input validation
	-- Check 1 : Validate the Ship Number
    
	IF v_ship_no IS NULL 
    THEN
       SET out_message  = "Transaction rolled back : Ship number is not entered";
	   SIGNAL SQLSTATE '45000'
	   SET MESSAGE_TEXT = out_message;
	END IF;
   
    -- Check 2: Validate transaction date is after contract start date and not in future 
	SELECT Start_Date INTO l_start_date 
	FROM ci_contract
	WHERE Tank_Id = v_tank_Id AND Cust_id = v_cust_id;
    
    SELECT v_txn_date,l_start_date,v_tank_Id,v_cust_id;    -- for debug
	IF(v_txn_date < l_start_date) OR (v_txn_date > "2025-03-31")THEN 
       SET out_message  = "Transaction rolled back : Invalid Transaction Date";
	   SIGNAL SQLSTATE '45000'
	   SET MESSAGE_TEXT = out_message;
	END IF; 
	
     -- Check 3: Validate quantity + current balance doesn't exceed tank's max threshold 
	SELECT Bal_Qty, Max_threshold INTO l_tank_balance_qty, l_tank_max_threshold
	FROM ci_tank
	WHERE Tank_Id = v_tank_id;
       	
    IF (l_tank_balance_qty + v_qty) > l_tank_max_threshold THEN
		SET out_message  = concat("The Quantity filled : " ,v_qty," is beyond the Max Threshold : ",l_tank_max_threshold ," for the Tank : ",v_tank_id);
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message;
	END IF;
       
	-- Check 4: Verify active contract exists for the tank and customer
	SELECT status INTO l_status 
	FROM ci_contract
	WHERE Tank_Id = v_tank_Id AND Cust_id = v_cust_id;
	
	IF l_status = 'C' THEN -- IF the contract status is (C)Closed , then print error
		SET out_message  = concat("Transaction rolled back : No Active Contract Exists for Tank : " ,v_tank_id , " and Customer:" , v_cust_id);
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message; 
	
    -- IF the Status is (A)Active , insert record into the ci_tankfill Table with status A(Active)
	-- and OP_Code (operation) is Tank Filling
	ELSEIF l_status = 'A' AND ((l_tank_balance_qty+ v_qty) < l_tank_max_threshold) THEN 
		SET out_message   = concat("Active Contract Exists for Tank : " ,v_tank_id , " and Customer:" , v_cust_id);
		SET l_tank_status = "A";
		SET l_op_code     = "FILLTANK";
            
	-- SELECT Tank_Id , Cust_ID , Txn_Date , Ship_No , Op_Code , Status, Qty FROM ci_tankfill;
	-- SELECT v_tank_id, v_cust_id , v_txn_date , v_ship_no , l_op_code , l_tank_status, v_qty;
	INSERT INTO ci_tankfill
		   ( Tank_Id , Cust_ID , Txn_Date , Ship_No , Op_Code , Status, Qty )
	VALUES
		   ( v_tank_id, v_cust_id , v_txn_date , v_ship_no , l_op_code , l_tank_status, v_qty);
	
    SET out_message = concat( "A new record is inserted for Customer in ci_tankfill Table", v_cust_Id," ,Tank_ID : ",v_tank_id,"  and transaction is committed successfully");
	COMMIT; -- End of Transaction
        
  END IF; 
        
END $$
DELIMITER ; -- End of the Procedure 

-- Inserting 5 Tank Fill Records.
CALL sp_fill_tank(9004,5004,"2024-12-30","MH001",7000.00,@tank_fill_msg);
CALL sp_fill_tank(9007,5001,"2025-01-05","AB001",3000.00,@tank_fill_msg);
CALL sp_fill_tank(9006,5012,'2025-02-18',"GS099",9000.00,@tank_fill_msg);
CALL sp_fill_tank(9002,5002,'2025-02-07',"RS232",800.00,@tank_fill_msg);
CALL sp_fill_tank(9001,5009,'2025-02-22',"XY940",500.00,@tank_fill_msg);
CALL sp_fill_tank(9001,5009,'2025-02-22',"X2940",500.00,@tank_fill_msg);
SELECT @tank_fill_msg;



-- Creating a Trigger Debug Log Table 
DROP TABLE IF EXISTS debug_log;
CREATE TABLE debug_log  ( message VARCHAR(100));
SELECT * FROM debug_log;

   
/* ----------------------------------------------------------------------------- */
/* Creating the  " AFTER INSERT TRIGGER ON Tankfill " table
   This is the After Insert TRIGGER that gets automatically executed WHEN a SUCCESSFUL record is entered 
   in the ci_Tankfill table
   This trigger Updates the Balance Quantity in the ci_tank Table along with Logging Entries into 
   Translog Table for FIllTANk operation */
/* ----------------------------------------------------------------------------- */
DROP TRIGGER IF EXISTS Update_Tank_Bal_After_TankFill;

DELIMITER //
CREATE TRIGGER Update_Tank_Bal_After_TankFill
AFTER  INSERT  ON ci_tankfill
FOR EACH ROW
BEGIN
     
     INSERT INTO debug_log (message) VALUES ("Trigger: Update_Tank_Bal_After_TankFill is called");
     UPDATE ci_tank
	 SET Bal_Qty = (Bal_Qty + New.Qty)-- Use NEW to access the column Qty from the ci_Tankfill Table which is just inserted from the store procedure
	 WHERE Tank_ID = New.Tank_ID; -- access the newly added Tank_Id from the ci_Tank Table 
      
	 INSERT INTO ci_translog
            ( Cust_ID, Op_code, Txn_Date, Txn_qty)
	 VALUES 
			(NEW.Cust_ID, NEW.Op_Code, NEW.Txn_Date, NEW.Qty);
	 INSERT INTO debug_log (message) VALUES ("Updated tank and Translog Table, Exiting the Trigger Update_Tank_Bal_After_TankFill ");
END ;
//
DELIMITER ; -- END of TRIGGER
