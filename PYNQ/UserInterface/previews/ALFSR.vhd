LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY ALFSR IS
    PORT
    (
        P_in               : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        Clk, En, Rst, Load : IN STD_LOGIC;
        S_out, Valid       : OUT STD_LOGIC
    );
END ALFSR;

ARCHITECTURE behavioral OF ALFSR IS
    SIGNAL CurrState, NextState : STD_LOGIC_VECTOR(255 DOWNTO 0);
    SIGNAL Feedback             : STD_LOGIC;

BEGIN
    PROCESS (Clk)
    BEGIN
        IF RISING_EDGE(Clk) THEN
            IF (Rst = '1') THEN
                CurrState <= (OTHERS => '0');
            ELSIF (En = '1') THEN
                IF (Load = '1') THEN
                    CurrState <= P_in;
                ELSE
                    CurrState <= NextState;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    Feedback  <= CurrState(255) XOR CurrState(253) XOR CurrState(252) XOR CurrState(250);
    NextState <= Feedback & CurrState(255 DOWNTO 1);
    S_out     <= CurrState(0);

    Valid <= '0' WHEN CurrState = (CurrState'RANGE => '0') OR CurrState = (CurrState'RANGE => '1') ELSE
        '1';
END behavioral;