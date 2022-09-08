LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY FA IS
    PORT
    (
        A, B, Cin : IN STD_LOGIC;
        S, Cout   : OUT STD_LOGIC
    );
END FA;

ARCHITECTURE dataflow OF FA IS
BEGIN
    S    <= A XOR B XOR Cin;
    Cout <= (A AND B) OR (Cin AND A) OR (Cin AND B);
END dataflow;