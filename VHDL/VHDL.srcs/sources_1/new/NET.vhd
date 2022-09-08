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
    SIGNAL buf : STD_LOGIC; -- internal buffer

BEGIN
    -- AND-only version of "NOT(0 XNOR 2 XNOR 3 XNOR 5) = 0 XOR 2 XOR 3 XOR 5", where the four literals
    -- are the same taps as the ALFSR [now counting FROM 0 TO 255 & considering complemented values].
    -- cfr. https://www.wolframalpha.com/input?i=a+xor+b+xor+c+xor+d
    Fb_out <= (NOT (Chain_in(0) AND Chain_in(2) AND Chain_in(3) AND Chain_in(5))) AND
        (NOT (Chain_in(0) AND Chain_in(2) AND NOT Chain_in(3) AND NOT Chain_in(5))) AND
        (NOT (Chain_in(0) AND NOT Chain_in(2) AND Chain_in(3) AND NOT Chain_in(5))) AND
        (NOT (Chain_in(0) AND NOT Chain_in(2) AND NOT Chain_in(3) AND Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND Chain_in(2) AND Chain_in(3) AND NOT Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND Chain_in(2) AND NOT Chain_in(3) AND Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND NOT Chain_in(2) AND Chain_in(3) AND Chain_in(5))) AND
        (NOT (NOT Chain_in(0) AND NOT Chain_in(2) AND NOT Chain_in(3) AND NOT Chain_in(5)));

    -- Exclusive-or Sum-of-Products (ESOP) Form for "a XOR (b AND NOT c) XOR (b AND d)", by means of
    -- which the same operation of the fulladder is performed beforehands [so that the whole computation
    -- can be simplified to the contribution of the LFSR alone]. Here, the four literals are (respectvely):
    -- a - LFSR serial output, b - enabler unique output, c - scrambler serial output, d - carry in bit.
    -- cfr. https://www.wolframalpha.com/input?i=a+xor+%28b+and+not+c%29+xor+%28b+and+d%29
    buf <= (Ctrl_in(2) AND Ctrl_in(0) AND NOT R_in) XOR
        (Ctrl_in(2) AND NOT Ctrl_in(0) AND R_in) XOR
        (Ctrl_in(2) AND NOT Ctrl_in(1) AND Ctrl_in(0) AND R_in) XOR
        (Ctrl_in(2) AND NOT Ctrl_in(1) AND NOT Ctrl_in(0) AND NOT R_in) XOR
        (NOT Ctrl_in(2) AND Ctrl_in(1) AND Ctrl_in(0) AND R_in) XOR
        (NOT Ctrl_in(2) AND Ctrl_in(1) AND NOT Ctrl_in(0) AND NOT R_in);

    -- Algebraic Normal Form (ANF) for "(a AND NOT b) OR (a AND c) OR (NOT b AND c)", which represents
    -- the carry out bit, only recomputed outside of the fulladder this time. The three literals are,
    -- in order of appearance: a - LFSR serial output, b - scrambler serial output, c - carry in bit.
    -- cfr. https://www.wolframalpha.com/input?i=%28a+and+not+b%29+or+%28a+and+c%29+or+%28not+b+and+c%29
    R_out <= buf XOR R_in XOR (buf AND Ctrl_in(0)) XOR
        (buf AND R_in) XOR (Ctrl_in(0) AND R_in);

    Op_out <= buf; -- output assignment
END dataflow;