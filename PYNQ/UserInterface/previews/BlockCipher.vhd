LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY BlockCipher IS
    PORT
    (
        ALFSR_PARALLEL_IN  : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
        LFSR_SERIAL_IN     : IN STD_LOGIC;
        SEQUENTIAL_ENABLE  : IN STD_LOGIC;
        CLOCK              : IN STD_LOGIC;
        RESET              : IN STD_LOGIC;
        LOAD_0             : IN STD_LOGIC;
        LOAD_A             : IN STD_LOGIC;
        LFSR_DEBUG_OUT     : OUT STD_LOGIC;
        ALFSR_DEBUG_OUT    : OUT STD_LOGIC;
        FA_DEBUG_OUT       : OUT STD_LOGIC;
        EDGE_DEBUG_OUT     : OUT STD_LOGIC;
        NET_DEBUG_OUT      : OUT STD_LOGIC;
        RESULTS_SERIAL_OUT : OUT STD_LOGIC;
        VALID_DATA         : OUT STD_LOGIC
    );
END BlockCipher;

ARCHITECTURE behavioral OF BlockCipher IS
    COMPONENT LFSR
        PORT
        (
            S_in, Clk, En, Rst, S_Load, P_Load, Count, Fb_in : IN STD_LOGIC;
            P_in                                             : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
            P_out                                            : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
            S_out, A_out, Valid, Fb_out                      : OUT STD_LOGIC
        );
    END COMPONENT;
    COMPONENT ALFSR
        PORT
        (
            P_in               : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
            Clk, En, Rst, Load : IN STD_LOGIC;
            S_out, Valid       : OUT STD_LOGIC
        );
    END COMPONENT;
    COMPONENT FA
        PORT
        (
            A, B, Cin : IN STD_LOGIC;
            S, Cout   : OUT STD_LOGIC
        );
    END COMPONENT;
    COMPONENT EDGE
        PORT
        (
            Fb_in, Val_in, Clk, Rst : IN STD_LOGIC;
            Ctrl_out                : OUT STD_LOGIC
        );
    END COMPONENT;
    COMPONENT NET
        PORT
        (
            Chain_in              : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
            Ctrl_in               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            R_in                  : IN STD_LOGIC;
            R_out, Fb_out, Op_out : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL cin, cout, count_0, out_0, out_1, out_a, ack_0, ack_a, ack_out, fb_0, fb_a, ed_out, rin, rout, nt_out, sum : STD_LOGIC;

    SIGNAL seq  : STD_LOGIC_VECTOR(255 DOWNTO 0);
    SIGNAL ctrl : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN
    LFSR_COMP : LFSR PORT MAP
        (LFSR_SERIAL_IN, CLOCK, SEQUENTIAL_ENABLE, RESET, LOAD_0, LOAD_A, count_0, fb_a, ALFSR_PARALLEL_IN, seq, out_0, out_1, ack_0, fb_0);
    ALFSR_COMP : ALFSR PORT
    MAP (ALFSR_PARALLEL_IN, CLOCK, SEQUENTIAL_ENABLE, RESET, LOAD_A, out_a, ack_a);
    FA_COMP : FA PORT
    MAP (nt_out, out_a, cin, sum, cout);
    EDGE_COMP : EDGE PORT
    MAP (fb_0, ack_out, CLOCK, RESET, ed_out);
    NET_COMP : NET PORT
    MAP (seq, ctrl, rin, rout, fb_a, nt_out);

    PROCESS (CLOCK)
    BEGIN
        IF RISING_EDGE(CLOCK) THEN
            IF (RESET = '1') THEN
                cin                <= '0';
                rin                <= '0';
                VALID_DATA         <= '0';
                RESULTS_SERIAL_OUT <= '0';
                LFSR_DEBUG_OUT     <= '0';
                ALFSR_DEBUG_OUT    <= '0';
                FA_DEBUG_OUT       <= '0';
                EDGE_DEBUG_OUT     <= '0';
                NET_DEBUG_OUT      <= '0';
            ELSIF (SEQUENTIAL_ENABLE = '1') THEN
                cin        <= cout;
                rin        <= rout;
                VALID_DATA <= ack_out;
                IF (ack_out = '1') THEN
                    RESULTS_SERIAL_OUT <= sum;
                    LFSR_DEBUG_OUT     <= out_0;
                    ALFSR_DEBUG_OUT    <= out_a;
                    FA_DEBUG_OUT       <= sum;
                    EDGE_DEBUG_OUT     <= ed_out;
                    NET_DEBUG_OUT      <= nt_out;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    ctrl <= out_0 & ed_out & out_1;

    ack_out <= ack_0 AND ack_a;
    count_0 <= '1' WHEN ack_0 = '0' ELSE
        '0';
END behavioral;