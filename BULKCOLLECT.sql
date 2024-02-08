Drop Table T_BulkCollect;

Drop Table T_BulkCollBKP;


Create Table T_BulkCollect
(
    id int,
    order_id int,
    product_code varchar2(3),
    amount_item number,
    date_sale date
);


Create Table T_BulkCollBKP
(
    id int,
    order_id int,
    product_code varchar2(3),
    amount number,
    date_sale date
);




Insert Into T_BulkCollect
Select
    RowNum Id,
    floor(dbms_random.value(90,9000)) order_id,
    dbms_random.String('U', 3) product_code,
    floor(dbms_random.value(90,9000)) amount,
    Sysdate - floor(dbms_random.value(1,900)) date_sale
from dual connect by level <= 50000;

Select * from T_BulkCollect Where Order_Id < 1000;
Select Count(*) from T_BulkCollect Where Order_Id < 10000;

--Alter Table T_BulkCollect Add DiscAmount number;

--Truncate Table T_BulkCollect;



Set ServerOutput On;

-- Example 1 : Insert data WITH Cursor WITHOUT Bulk Collect
/
Declare
    t_Start Number Default DBMS_UTILITY.Get_Time;
    
    Cursor Cur1 is
    Select
        *
    from
        T_BulkCollect
    where Order_Id < 10000
    ;
Begin
    for varCur1 in Cur1 loop
        Insert Into T_BulkCollBKP Values
        (   varCur1.Id,
            varCur1.order_id,
            varCur1.product_code,
            varCur1.amount,
            varCur1.date_sale
        );
    end loop;
    Commit;


    DBMS_OUTPUT.PUT_LINE('##WITH Cursor WITHOUT Bulk Collect: ' || Round((DBMS_UTILITY.Get_Time - t_Start)/100, 2) || ' Seconds' );
End;
/

-- Example 2 : Insert data WITH Bulk Collect and Loop
Truncate Table T_BulkCollBKP;

Declare
    t_Start Number Default DBMS_UTILITY.Get_Time;
    
    Type BulkCollType is table of T_BulkCollect%RowType;
    
    varBulkColl BulkCollType;
Begin
    Select
        *
    bulk collect into varBulkColl
    from
        T_BulkCollect
    where Order_Id < 10000;
    
    for i in 1..varBulkColl.Count loop
        Insert Into T_BulkCollBKP Values
        (   varBulkColl(i).Id,
            varBulkColl(i).order_id,
            varBulkColl(i).product_code,
            varBulkColl(i).amount,
            varBulkColl(i).date_sale
        );
    end loop;
    Commit;



    DBMS_OUTPUT.PUT_LINE('##WITH Table Type WITH Bulk Collect: ' || Round((DBMS_UTILITY.Get_Time - t_Start)/100, 2) || ' Seconds' );
End;
/

-- Example 3 : Insert data WITH Table Type and Bulk Collect and FORALL

Declare
    t_Start Number Default DBMS_UTILITY.Get_Time;
    
    Type BulkCollType is table of T_BulkCollect%RowType;
    
    varBulkColl BulkCollType;
    
    Cursor Cur1 is
    Select
        *
    from
        T_BulkCollect
    where Order_Id < 10000
    ;

Begin
    OPEN Cur1;
    LOOP
        FETCH Cur1 bulk collect into varBulkColl;
        FORALL i in 1..varBulkColl.Count
            Insert Into T_BulkCollBKP Values
            (   varBulkColl(i).Id,
                varBulkColl(i).order_id,
                varBulkColl(i).product_code,
                varBulkColl(i).amount,
                varBulkColl(i).date_sale
            );
        
        Exit when Cur1%NotFound;
    END LOOP;
    CLOSE Cur1;
    Commit;


    DBMS_OUTPUT.PUT_LINE('##WITH Table Type and Bulk Collect and FORALL: ' || Round((DBMS_UTILITY.Get_Time - t_Start)/100, 2) || ' Seconds' );
End;
/


-- Example 4 : Insert data WITH Table Type and Bulk Collect LIMIT and FORALL

Declare
    t_Start Number Default DBMS_UTILITY.Get_Time;
    
    Type BulkCollType is table of T_BulkCollect%RowType;
    
    varBulkColl BulkCollType;
    
    Cursor Cur1 is
    Select
        *
    from
        T_BulkCollect
    where Order_Id < 10000
    ;

Begin

    OPEN Cur1;
    LOOP
        FETCH Cur1 bulk collect into varBulkColl LIMIT 10000;
        FORALL i in 1..varBulkColl.Count
            Insert Into T_BulkCollBKP Values
            (   varBulkColl(i).Id,
                varBulkColl(i).order_id,
                varBulkColl(i).product_code,
                varBulkColl(i).amount,
                varBulkColl(i).date_sale
            );
        Exit when Cur1%NotFound;
    END LOOP;
    Commit;


    DBMS_OUTPUT.PUT_LINE('##WITH Table Type and Bulk Collect LIMIT and FORALL: ' || Round((DBMS_UTILITY.Get_Time - t_Start)/100, 2) || ' Seconds' );
End;
/

-- Example 5 : Direct Insert data

Declare
    t_Start Number Default DBMS_UTILITY.Get_Time;

Begin
    Insert Into T_BulkCollBKP
    Select
        *
    from
        T_BulkCollect
    where Order_Id < 10000;

    Commit;


    DBMS_OUTPUT.PUT_LINE('##Direct Insert Data: ' || Round((DBMS_UTILITY.Get_Time - t_Start)/100, 2) || ' Seconds' );
End;
/

