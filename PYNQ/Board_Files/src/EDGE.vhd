LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY EDGE IS
    PORT
    (
        Fb_in, Val_in, Ld_in, Clk, En, Rst : IN STD_LOGIC;
        Ctrl_out                           : OUT STD_LOGIC
    );
END EDGE;

ARCHITECTURE behavioral OF EDGE IS
    TYPE STATE IS (S4, S3, S2, S1, S0);
    SIGNAL CS, NS : STATE;
    SIGNAL i, j   : UNSIGNED(1 DOWNTO 0);
    SIGNAL D, E   : STD_LOGIC;

BEGIN
    D <= (NOT ((NOT i(1)) OR (NOT i(0)) OR (NOT Fb_in))) OR
        (NOT (i(1) OR Fb_in)) OR (NOT (i(0) OR Fb_in));

    Ctrl_out <= '1' WHEN CS = S1 ELSE
        '1' WHEN (CS = S2) AND (E = '1') ELSE
        '0';

    SYNCH : PROCESS (Clk)
    BEGIN
        IF RISING_EDGE(Clk) THEN
            IF (Rst = '1') THEN
                CS <= S4;
                i  <= (OTHERS => '0');
            ELSIF (En = '1') THEN
                CS <= NS;
                i  <= j;
            END IF;
        END IF;
    END PROCESS SYNCH;

    COMB : PROCESS (CS, i, Rst, Val_in, Ld_in, D)
    BEGIN
        E <= '0';
        j <= (OTHERS => '0');
        CASE (CS) IS
            WHEN S4 =>
                IF (Rst = '1') THEN
                    NS <= S4;
                ELSIF (Ld_in = '1') THEN
                    NS <= S2;
                ELSE
                    NS <= S3;
                END IF;
            WHEN S3 =>
                IF (Ld_in = '1') THEN
                    NS <= S2;
                ELSE
                    NS <= S3;
                END IF;
            WHEN S2 =>
                IF (D = '1') THEN
                    IF (Val_in = '1') THEN
                        E  <= '1';
                        NS <= S1;
                    ELSE
                        NS <= S2;
                        j  <= i + 1;
                    END IF;
                ELSE
                    NS <= S0;
                END IF;
            WHEN S1 =>
                NS <= S1;
            WHEN S0 =>
                NS <= S0;
            WHEN OTHERS =>
                NS <= S4;
        END CASE;
    END PROCESS COMB;
END behavioral;