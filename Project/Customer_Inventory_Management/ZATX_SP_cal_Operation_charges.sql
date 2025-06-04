USE Proj_Zatx;
DROP PROCEDURE IF EXISTS sp_Cal_Op_Charges  ;

-- --------------------------------------------------------------------------------------------------
/*Creating a procedure sp_Cal_Op_Charges is used to calculate Operation_Charges and Rental Charges */
-- Created on : 30.04.2025
-- --------------------------------------------------------------------------------------------------

DELIMITER $$
CREATE PROCEDURE sp_Cal_Op_Charges(IN user_sel_cust_id INT )
 BEGIN
 
  -- -------------------------------------------------------------------------------------------------
  /* ***********  Calculate Operation Charges using CTE****************/
  WITH CTE_op_log_join AS (
		SELECT l.Cust_Id ,cu.Name,l.Txn_date,l.op_code Operation, Amount `Charge\Ton` , Txn_Qty , Amount*Txn_qty as Operation_Charges
		FROM ci_translog l
		JOIN ci_operation c ON c.op_code = l.op_code
		JOIN ci_customer cu ON l.cust_ID = cu.cust_ID
	    WHERE l.Cust_ID = user_sel_cust_id
	),
 CTE_Total AS(
		SELECT distinct "TOTAL CHARGES = " as cust_ID,"" as Name,"" as Txn_date,"" as Operation,"" as `Charge\ton`,"" as Txn_qty,
		SUM(Operation_Charges)as TOTAL_Operation_Charges FROM CTE_op_log_join
	)
    
  SELECT * FROM CTE_op_log_join
  UNION ALL 
  SELECT * FROM CTE_Total;

-- -------------------------------------------------------------------------------------------------
    
/* ***********  Calculate Rental Charges ****************/
	SELECT co.cust_ID,cu.name Cust_Name,ta.tank_ID,
	ta.Bal_Qty *(SELECT Amount from ci_operation where Op_code ="RENTAL")RENTAL_CHARGES from ci_Tank ta
	JOIN ci_contract co ON co.tank_ID = ta.tank_ID
    JOIN ci_customer cu ON cu.cust_ID = co.cust_ID
    WHERE co.cust_ID = user_sel_cust_id;
 END $$
DELIMITER ;
                                   

CALL sp_Cal_Op_Charges(5009);

