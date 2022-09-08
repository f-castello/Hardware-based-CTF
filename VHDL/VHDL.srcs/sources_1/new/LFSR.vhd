LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY LFSR IS
    PORT
    (
        S_in, Clk, En, Rst, S_Load, P_Load, Count, Fb_in : IN STD_LOGIC;
        P_in                                             : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        P_out                                            : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
        S_out, A_out, Valid, Fb_out                      : OUT STD_LOGIC
    );
END LFSR;

ARCHITECTURE behavioral OF LFSR IS
    SIGNAL CurrState, NextState, AltState, AltStatePrime : STD_LOGIC_VECTOR(255 DOWNTO 0);
    SIGNAL Feedback                                      : STD_LOGIC;
    SIGNAL cc_256                                        : UNSIGNED(8 DOWNTO 0);

BEGIN
    PROCESS (Clk)
        VARIABLE Scr, sh : STD_LOGIC_VECTOR(255 DOWNTO 0);
        CONSTANT one     : STD_LOGIC_VECTOR(255 DOWNTO 0) := (255 DOWNTO 1 => '0') & '1';
    BEGIN
        IF RISING_EDGE(Clk) THEN
            IF (Rst = '1') THEN
                CurrState <= (OTHERS => '0');
                cc_256    <= (OTHERS => '0');
                AltState  <= (OTHERS => '0');
                Scr := (OTHERS       => '0');
                sh  := (OTHERS       => '0');
            ELSIF (En = '1') THEN
                IF (S_Load = '1') THEN
                    CurrState(254 DOWNTO 0) <= CurrState(255 DOWNTO 1);
                    CurrState(255)          <= S_in; -- Serial In
                    IF (Count = '1') THEN            -- avoid affecting output after initialization
                        cc_256 <= cc_256 + 1;            -- count the first 256 cc of 'Load'
                    END IF;
                ELSE
                    CurrState <= NextState;
                END IF;
                IF (P_Load = '1') THEN
                    FOR i IN P_in'RANGE LOOP
                        IF (P_in(i) = '0') THEN
                            sh  := STD_LOGIC_VECTOR(SHIFT_LEFT(UNSIGNED(one), P_in'HIGH - i)); -- switch endianne & complement all bits
                            Scr := Scr OR sh;                                                  -- shift the correct 1 into the scrambled seed
                        END IF;
                    END LOOP;
                    AltState <= Scr;
                ELSE
                    AltState <= AltStatePrime;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    Feedback      <= CurrState(255) XOR CurrState(203); -- https://datacipy.cz/lfsr_table.pdf#page=3 (n = 255 @ LFSR-2)
    NextState     <= Feedback & CurrState(255 DOWNTO 1);
    AltStatePrime <= AltState(254 DOWNTO 0) & (NOT Fb_in);

    S_out <= CurrState(0);  -- Serial Out
    A_out <= AltState(255); -- Altered Out
    Valid <= '1' WHEN cc_256(8) = '1' AND CurrState /= (CurrState'RANGE => '0') ELSE
        '0'; -- output data is valid only after loading in 256 bits and shifting out all the initial zeros, and only if the LFSR is not zeroed-out (idle state)

    Fb_out <= Feedback; -- send feedback to enabler
    P_out  <= AltState; -- send altered state to the combinational network
END behavioral;