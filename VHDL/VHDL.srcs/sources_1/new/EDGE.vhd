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
    -- The combinational network gets activated iff exactly 1 feedback
    -- every 4 is HIGH during LFSR initialization: an internal signal
    -- is kept for memory together with an AND port, while the actual
    -- value gets sampled whenever the LFSR ciphertext stream is valid.

    TYPE STATE IS (S4, S3, S2, S1, S0); -- two-process Mealy FSM
    SIGNAL CS, NS : STATE;
    SIGNAL i, j   : UNSIGNED(1 DOWNTO 0);
    SIGNAL D, E   : STD_LOGIC;

BEGIN
    -- 'D' should be left True in order to enable the combinational network:
    -- +----+-------+---+
    -- |  i | Fb_in | D |
    -- +====+=======+===+
    -- | 00 |   0   | T |
    -- +----+-------+---+
    -- | 01 |   0   | T |
    -- +----+-------+---+
    -- | 10 |   0   | T |
    -- +----+-------+---+
    -- | 11 |   1   | T |
    -- +----+-------+---+
    -- | 00 |   1   | F |
    -- +----+-------+---+
    -- | 01 |   1   | F |
    -- +----+-------+---+
    -- | 10 |   1   | F |
    -- +----+-------+---+
    -- | 11 |   0   | F |
    -- +----+-------+---+
    -- cfr. http://tma.main.jp/logic/logic.php?lang=en&type=3&v0=a&v1=b&v2=c&00=1&01=0&02=1&03=0&04=1&05=0&06=0&07=1

    -- OR-only version for "(a AND b AND c) OR (NOT a AND NOT c) OR (NOT b AND NOT c)",
    -- where the three literals are, in alphabetical order: i(1), i(0), Fb_in.
    -- cfr. https://www.wolframalpha.com/input?i=%28a+and+b+and+c%29+or+%28not+a+and+not+c%29+or+%28not+b+and+not+c%29
    D <= (NOT ((NOT i(1)) OR (NOT i(0)) OR (NOT Fb_in))) OR
        (NOT (i(1) OR Fb_in)) OR (NOT (i(0) OR Fb_in));

    Ctrl_out <= '1' WHEN CS = S1 ELSE
        '1' WHEN (CS = S2) AND (E = '1') ELSE
        '0'; -- concurrent output assignment

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
            WHEN S4 => -- reset
                IF (Rst = '1') THEN
                    NS <= S4;
                ELSIF (Ld_in = '1') THEN
                    NS <= S2;
                ELSE
                    NS <= S3;
                END IF;
            WHEN S3 => -- idle
                IF (Ld_in = '1') THEN
                    NS <= S2;
                ELSE
                    NS <= S3;
                END IF;
            WHEN S2 => -- evaluation
                -- 'E' is used to check the last bit of PT
                IF (D = '1') THEN      -- correct input
                    IF (Val_in = '1') THEN -- loading done
                        E  <= '1';
                        NS <= S1;
                    ELSE -- loading underway
                        NS <= S2;
                        j  <= i + 1;
                    END IF;
                ELSE -- wrong input
                    NS <= S0;
                END IF;
            WHEN S1 => -- high out
                NS <= S1;
            WHEN S0 => -- low out
                NS <= S0;
            WHEN OTHERS => -- faults
                NS <= S4;
        END CASE;
    END PROCESS COMB;
END behavioral;