USE Proj_Zatx;
DROP PROCEDURE IF EXISTS sp_truck_exit_weight;
-- -------------------------------------------------------------------------------------------------
/*
Creating a procedure sp_truck_exit_weight is used ti complete truck loading by recording exit weight
(STAGE 2 of Truck Loading)
Validations :
	o Find pending entry for this truck number ( pending entry is where exit wt is null)
	o Verify exit weight is greater than entry weight
	o Check if tank has sufficient quantity after loading onto the truck
   
After the validation , exit and net weight are updated into ci_truckload Table . UPDATE trigger 
auotmatically updates the tank balance in the ci_tank Master Table which is the differnce of qty 
available in the tank and qty newlt filled into the truck from the tank and
 also log entries into translog
Created on : 30.04.2025
*/
-- -------------------------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_truck_exit_weight(
									  IN  v_truck_no  VARCHAR(15),
									  IN  v_exit_wt   DECIMAL(15,2),
                                      OUT out_message VARCHAR(100)
									  )
BEGIN
    -- declare local variables 
	DECLARE l_truck_exist    INT;
    DECLARE l_tank_id        INT;
	DECLARE l_entry_wt       DECIMAL(15,2);
	DECLARE l_net_wt         DECIMAL(15,2);
	DECLARE l_min_threshold  DECIMAL(15,2);
	DECLARE l_bal_qty        DECIMAL(15,2);
    /* This block is executed i.e The transaction is rolled back when any SQL exception happens*/
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
        ROLLBACK;
	    RESIGNAL;-- Do this if an error occurs
	END;
      
	/* Start a new transaction to ensure data integrity of the operations */
	START TRANSACTION; 
    
      -- Start of input validation
      -- Check 1 : Validate the exit truck to be the same as the entered truck 
	 SELECT count(*) INTO l_truck_exist FROM ci_truckload 
	 WHERE Truck_No = v_truck_no ;
      
	 IF l_truck_exist = 0 THEN
		SET out_message = "Transaction rolled back : No truck with this number has gone in ";
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = out_message;
	 END IF;
    
    -- Check 2 : Validate Exit weight to be more than the exit weight 
	 SELECT Truck_entry_wt,Tank_ID INTO l_entry_wt,l_tank_id FROM ci_truckload
     WHERE Truck_No = v_truck_no ;
     IF v_exit_wt <=l_entry_wt THEN 
		SET out_message  = concat("Transaction rolled back: Truck exit weight : ",v_exit_wt, "cannot be less than Entry weight : ",l_entry_wt);
		SIGNAL SQLSTATE '45000' 
		SET MESSAGE_TEXT = out_message;
	 END IF;
      
      -- Calculating the weight of the Loaded product in the tank
     SET l_net_wt = v_exit_wt - l_entry_wt;
      
      -- SELECT Net_wt,Truck_exit_wt FROM ci_truck_load WHERE Truck_No = v_truck_no and Truck_exit_wt is NULL;
      
      -- Update the value of the exit_weight and the ne weight in the Ci_truckload Table
     UPDATE ci_truckload SET Net_wt = l_net_wt, Truck_exit_wt = v_exit_wt
     WHERE Truck_No = v_truck_no and Truck_exit_wt is NULL;
	 COMMIT;
      /* Update trigger is called after updatinh exit and net weight into truckload . 
      In the trigger ci_tank will be updated with the balance weight and logs entry into the Translog Table for load truck operartion*/
      
      -- Check 3 : This Validation is to check if the balance in the tank after loaded onto the truck falls 
      -- below the min_threshold value 
	SELECT Bal_Qty ,Min_Threshold INTO l_bal_qty,l_min_threshold 
	FROM ci_tank
	WHERE Tank_ID =l_tank_id;
	SELECT l_bal_qty,l_min_threshold;
	IF l_bal_qty <= l_min_threshold THEN
	   SIGNAL SQLSTATE '01000'
	   SET MESSAGE_TEXT = 'Tank value is less , need to be refilled ';
	END IF;
    COMMIT; -- End of Transaction 
  END $$
DELIMITER ;-- End of Store Procedure 


-- Inserting 10 records into truck_exit_weight
CALL sp_truck_exit_weight("KA6035",16000.00,@truck_load_msg);
CALL sp_truck_exit_weight("KA2025",10300.00,@truck_load_msg);
CALL sp_truck_exit_weight("TS6125",17500.00,@truck_load_msg);
CALL sp_truck_exit_weight("TN9162", 5500.00,@truck_load_msg);
CALL sp_truck_exit_weight("KL9099", 5250.00,@truck_load_msg);
CALL sp_truck_exit_weight("X29400", 5050.00,@truck_load_msg);
SELECT @truck_load_msg;





/* ----------------------------------------------------------------------------- */
/* Creating the  " UPDATE  TRIGGER ON ci_truckload " table
   This is the Update Insert TRIGGER that gets automatically executed WHEN exit_wt and net_wt is updated into
   the record in ci_truckload table
   This trigger Updates the Balance Quantity in the ci_tank Table along with Inserting log Records for
   THE LOADTRUCK operation into ci_Translog Table */
/* ----------------------------------------------------------------------------- */
DROP TRIGGER IF EXISTS Update_Tank_Bal_After_TruckLoad;

DELIMITER //
CREATE TRIGGER Update_Tank_Bal_After_TruckLoad
AFTER  UPDATE  ON ci_truckload
FOR EACH ROW
BEGIN

      DECLARE l_bal_qty DECIMAL(15,2);
      DECLARE v_min_threshold DECIMAL(15,2);
      
      INSERT INTO debug_log (message) VALUES ("Trigger: Update_Tank_Bal_After_TruckLoad is called");
   	  UPDATE ci_tank
	  SET Bal_Qty = (Bal_Qty - New.Net_wt)
	  WHERE Tank_ID = Old.Tank_ID; -- Use OLD to access the column Tank_ID from the ci_truckload Table which is the old value it has from the sp_truck_entry_weight procedure
      
	  INSERT INTO ci_translog
			 ( Cust_ID, Op_code, Txn_Date, Txn_qty)
      VALUES 
			 ( NEW.Cust_ID, NEW.Op_Code, NEW.Txn_Date, NEW.Net_wt);
             
      INSERT INTO debug_log (message) 
      VALUES ("Updated tank and Translog Table, Exiting the Trigger Update_Tank_Bal_After_TruckLoad ");
END ;
 //
DELIMITER ; -- End of the trigger
    