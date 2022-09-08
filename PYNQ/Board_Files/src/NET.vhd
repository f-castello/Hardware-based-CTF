LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY NET IS
    PORT
    (
        Chain_in              : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        Ctrl_in               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        R_in                  : IN STD_LOGIC;
        R_out, Fb_out, Op_out : OUT STD_LOGIC
    );
END NET;

ARCHITECTURE dataflow OF NET IS
    SIGNAL buf : STD_LOGIC;

BEGIN
    Fb_out <= (NOT (Chain_in(0) AND Chain_in(2) AND Chain_in(3) AND Chain_in(5))) AND
        (NOT (Chain_in(0) AND Chain_in(2) AND NOT Chain_in(3) AND NOT Chain_in(5))) AND
        (NOT (Chain_in(0) AND NOT Chain_in(2) AND Chain_in(3) AND NOT Chain_in(5))) AND
        (NOT (Chain_in(0) AND NOT Chain_in(2) AND NOT Chain_in(3) AND Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND Chain_in(2) AND Chain_in(3) AND NOT Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND Chain_in(2) AND NOT Chain_in(3) AND Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND NOT Chain_in(2) AND Chain_in(3) AND Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND NOT Chain_in(2) AND NOT Chain_in(3) AND NOT Chain_in(5)));

    buf <= (Ctrl_in(2) AND Ctrl_in(0) AND NOT R_in) XOR
        (Ctrl_in(2) AND NOT Ctrl_in(0) AND R_in) XOR
        (Ctrl_in(2) AND NOT Ctrl_in(1) AND Ctrl_in(0) AND R_in) XOR
        (Ctrl_in(2) AND NOT Ctrl_in(1) AND NOT Ctrl_in(0) AND NOT R_in) XOR
        (NOT Ctrl_in(2) AND Ctrl_in(1) AND Ctrl_in(0) AND R_in) XOR
        (NOT Ctrl_in(2) AND Ctrl_in(1) AND NOT Ctrl_in(0) AND NOT R_in);

    R_out <= buf XOR R_in XOR (buf AND Ctrl_in(0)) XOR
        (buf AND R_in) XOR (Ctrl_in(0) AND R_in);

    Op_out <= buf;
END dataflow;