LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE STD.textio.ALL;
USE IEEE.std_logic_textio.ALL;

ENTITY tb_BlockCipher IS
END tb_BlockCipher;

ARCHITECTURE test OF tb_BlockCipher IS
	COMPONENT BlockCipher IS
		PORT
		(
			ALFSR_PARALLEL_IN  : IN STD_LOGIC_VECTOR(255 DOWNTO 0); -- ALFSR Parallel Input
			LFSR_SERIAL_IN     : IN STD_LOGIC;                      -- LFSR Serial Input
			SEQUENTIAL_ENABLE  : IN STD_LOGIC;                      -- FPGA Enable
			CLOCK              : IN STD_LOGIC;                      -- System Clock
			RESET              : IN STD_LOGIC;                      -- System Reset
			LOAD_0             : IN STD_LOGIC;                      -- Load Enable for LFSR
			LOAD_A             : IN STD_LOGIC;                      -- Load Enable for ALFSR
			LFSR_DEBUG_OUT     : OUT STD_LOGIC;                     -- Debug: LFSR
			ALFSR_DEBUG_OUT    : OUT STD_LOGIC;                     -- Debug: ALFSR
			FA_DEBUG_OUT       : OUT STD_LOGIC;                     -- Debug: Full Adder
			EDGE_DEBUG_OUT     : OUT STD_LOGIC;                     -- Debug: Enabler
			NET_DEBUG_OUT      : OUT STD_LOGIC;                     -- Debug: Combinational Network
			RESULTS_SERIAL_OUT : OUT STD_LOGIC;                     -- Serial Out
			VALID_DATA         : OUT STD_LOGIC                      -- LFSR and ALFSR Data Valid
		);
	END COMPONENT;

	CONSTANT T_CK     : TIME := 20 ns;                  -- Clock period, default 20ns = 50MHz
	FILE file_LFSR    : TEXT;                           -- LFSR Stream inputs (CHECK DATA_BLOCK LENGTH!)
	SIGNAL DATA_BLOCK : STD_LOGIC_VECTOR(255 DOWNTO 0); -- Data to feed to LFSR
	FILE file_ALFSR   : TEXT;                           -- ALFSR Parallel Input
	SIGNAL ALFSR_SEED : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL CLK_CNT    : UNSIGNED(11 DOWNTO 0);

	FILE file_OUT_BlockCipher : TEXT;
	FILE file_OUT_LFSR        : TEXT;
	FILE file_OUT_ALFSR       : TEXT;
	FILE file_OUT_FA          : TEXT;
	FILE file_OUT_EDGE        : TEXT;
	FILE file_OUT_NET         : TEXT;

	SIGNAL tb_CLOCK              : STD_LOGIC;
	SIGNAL tb_SEQUENTIAL_ENABLE  : STD_LOGIC;
	SIGNAL tb_RESET              : STD_LOGIC;
	SIGNAL tb_LOAD_0             : STD_LOGIC;
	SIGNAL tb_LOAD_A             : STD_LOGIC;
	SIGNAL tb_LFSR_SERIAL_IN     : STD_LOGIC;
	SIGNAL tb_ALFSR_PARALLEL_IN  : STD_LOGIC_VECTOR(255 DOWNTO 0);
	SIGNAL tb_RESULTS_SERIAL_OUT : STD_LOGIC;
	SIGNAL tb_VALID_DATA         : STD_LOGIC;
	SIGNAL tb_LFSR_DEBUG_OUT     : STD_LOGIC;
	SIGNAL tb_ALFSR_DEBUG_OUT    : STD_LOGIC;
	SIGNAL tb_FA_DEBUG_OUT       : STD_LOGIC;
	SIGNAL tb_NET_DEBUG_OUT      : STD_LOGIC;
	SIGNAL tb_EDGE_DEBUG_OUT     : STD_LOGIC;

BEGIN
	----- General Processes -----
	-- System Clock Generation
	CLOCK_PROC :
	PROCESS
	BEGIN
		tb_CLOCK <= '0';
		WAIT FOR T_CK / 2;
		tb_CLOCK <= '1';
		WAIT FOR T_CK / 2;
	END PROCESS CLOCK_PROC;
	-- Debug: Clock Period Counter
	CLK_DEBUG_PROC :
	PROCESS (tb_CLOCK, tb_RESET)
	BEGIN
		IF (tb_RESET = '1') THEN
			CLK_CNT <= (OTHERS => '0');
		ELSIF RISING_EDGE(tb_CLOCK) THEN
			CLK_CNT <= CLK_CNT + 1;
		END IF;
	END PROCESS CLK_DEBUG_PROC;
	-- FPGA Clock Management
	ENAB_PROC :
	PROCESS
	BEGIN
		tb_SEQUENTIAL_ENABLE <= '1';
		WAIT FOR 10000 * T_CK;
		tb_SEQUENTIAL_ENABLE <= '0';
		WAIT;
	END PROCESS ENAB_PROC;
	-- Initial System Reset
	RST_PROC :
	PROCESS
	BEGIN
		tb_RESET <= '1';
		WAIT FOR 5 * T_CK / 2;
		tb_RESET <= '0';
		WAIT;
	END PROCESS RST_PROC;
	-- Debug: Output Files
	OUT_STORE_PROC :
	PROCESS (tb_CLOCK)
		VARIABLE FILE_IS_OPEN  : BOOLEAN := FALSE;
		VARIABLE v_NBITS       : NATURAL := 0;
		VARIABLE v_NLINE       : NATURAL := 0;
		VARIABLE L_BlockCipher : line;
		VARIABLE L_LFSR        : line;
		VARIABLE L_ALFSR       : line;
		VARIABLE L_NET         : line;
		VARIABLE L_EDGE        : line;
		VARIABLE L_FA          : line;
	BEGIN
		IF NOT FILE_IS_OPEN THEN
			FILE_OPEN(file_OUT_BlockCipher, "OUT_BlockCipher.txt", WRITE_MODE);
			FILE_OPEN(file_OUT_LFSR, "OUT_LFSR.txt", WRITE_MODE);
			FILE_OPEN(file_OUT_ALFSR, "OUT_ALFSR.txt", WRITE_MODE);
			FILE_OPEN(file_OUT_FA, "OUT_FA.txt", WRITE_MODE);
			FILE_OPEN(file_OUT_NET, "OUT_NET.txt", WRITE_MODE);
			FILE_OPEN(file_OUT_EDGE, "OUT_EDGE.txt", WRITE_MODE);
			FILE_IS_OPEN := TRUE;
		END IF;

		IF RISING_EDGE(tb_CLOCK) THEN
			IF (tb_VALID_DATA = '1') THEN
				IF (v_NBITS < 256) THEN
					v_NBITS := v_NBITS + 1;
					v_NLINE := v_NLINE + 1;

					WRITE(L_BlockCipher, tb_RESULTS_SERIAL_OUT);
					WRITE(L_LFSR, tb_LFSR_DEBUG_OUT);
					WRITE(L_ALFSR, tb_ALFSR_DEBUG_OUT);
					WRITE(L_NET, tb_NET_DEBUG_OUT);
					WRITE(L_EDGE, tb_EDGE_DEBUG_OUT);
					WRITE(L_FA, tb_FA_DEBUG_OUT);

					IF v_NLINE = 64 THEN
						WRITELINE(file_OUT_BlockCipher, L_BlockCipher);
						WRITELINE(file_OUT_LFSR, L_LFSR);
						WRITELINE(file_OUT_ALFSR, L_ALFSR);
						WRITELINE(file_OUT_FA, L_FA);
						WRITELINE(file_OUT_NET, L_NET);
						WRITELINE(file_OUT_EDGE, L_EDGE);

						DEALLOCATE(L_BlockCipher);
						DEALLOCATE(L_LFSR);
						DEALLOCATE(L_ALFSR);
						DEALLOCATE(L_NET);
						DEALLOCATE(L_EDGE);
						DEALLOCATE(L_FA);
						v_NLINE := 0;
					END IF;
				ELSIF FILE_IS_OPEN THEN
					FILE_CLOSE(file_OUT_BlockCipher);
					FILE_CLOSE(file_OUT_LFSR);
					FILE_CLOSE(file_OUT_ALFSR);
					FILE_CLOSE(file_OUT_FA);
					FILE_CLOSE(file_OUT_NET);
					FILE_CLOSE(file_OUT_EDGE);
				ELSE
					REPORT "FILE N/A" SEVERITY ERROR;
				END IF;
			END IF;
		END IF;
	END PROCESS OUT_STORE_PROC;

	----- LFSR Processes -----
	-- Initialize Data for LFSR In
	DATA_INIT_LFSR_PROC :
	PROCESS
		VARIABLE file_LINE    : line;
		VARIABLE v_DATA_BLOCK : STD_LOGIC_VECTOR(255 DOWNTO 0);
	BEGIN
		file_open(file_LFSR, "LFSR_SOLUTION.txt", read_mode);
		READLINE(file_LFSR, file_LINE);
		READ(file_LINE, v_DATA_BLOCK);
		DATA_BLOCK <= v_DATA_BLOCK;
		WAIT;
	END PROCESS DATA_INIT_LFSR_PROC;
	-- Serial Data Input for LFSR
	LFSR_IN_PROC :
	PROCESS (tb_RESET, tb_SEQUENTIAL_ENABLE, tb_CLOCK)
		VARIABLE I : NATURAL := 0;
	BEGIN
		IF (tb_RESET = '1') THEN
			tb_LOAD_0         <= '0';
			tb_LFSR_SERIAL_IN <= '0';
			I := 0;
		ELSIF (tb_SEQUENTIAL_ENABLE = '1') AND RISING_EDGE(tb_CLOCK) THEN
			IF (I < 256) THEN
				tb_LOAD_0         <= '1';
				tb_LFSR_SERIAL_IN <= DATA_BLOCK(I);
				I := I + 1;
			ELSE
				tb_LOAD_0         <= '0';
				tb_LFSR_SERIAL_IN <= DATA_BLOCK(I - 1);
				I := I;
			END IF;
		END IF;
	END PROCESS LFSR_IN_PROC;

	----- ALFSR Processes -----
	-- Initialize Data for ALFSR In
	DATA_INIT_ALFSR_PROC :
	PROCESS
		VARIABLE file_LINE    : line;
		VARIABLE v_ALFSR_SEED : STD_LOGIC_VECTOR(255 DOWNTO 0);
	BEGIN
		file_open(file_ALFSR, "ALFSR_rand.txt", read_mode);
		READLINE(file_ALFSR, file_LINE);
		READ(file_LINE, v_ALFSR_SEED);
		ALFSR_SEED <= v_ALFSR_SEED;
		WAIT;
	END PROCESS DATA_INIT_ALFSR_PROC;
	-- Load Seed into ALFSR
	ALFSR_IN_PROC :
	PROCESS (tb_RESET, tb_SEQUENTIAL_ENABLE, tb_CLOCK)
		VARIABLE I : NATURAL := 0;
	BEGIN
		IF (tb_RESET = '1') THEN
			tb_LOAD_A            <= '0';
			tb_ALFSR_PARALLEL_IN <= ALFSR_SEED;
			I := 0;
		ELSIF (tb_SEQUENTIAL_ENABLE = '1') AND RISING_EDGE(tb_CLOCK) THEN
			IF (I = 0) THEN
				tb_LOAD_A            <= '1';
				tb_ALFSR_PARALLEL_IN <= ALFSR_SEED;
				I := 1;
			ELSE
				tb_LOAD_A            <= '0';
				tb_ALFSR_PARALLEL_IN <= ALFSR_SEED;
				I := 1;
			END IF;
		END IF;
	END PROCESS ALFSR_IN_PROC;

	----- DUT Instantiation -----
	DUT : BlockCipher PORT MAP
	(
		ALFSR_PARALLEL_IN  => tb_ALFSR_PARALLEL_IN,
		LFSR_SERIAL_IN     => tb_LFSR_SERIAL_IN,
		SEQUENTIAL_ENABLE  => tb_SEQUENTIAL_ENABLE,
		CLOCK              => tb_CLOCK,
		RESET              => tb_RESET,
		LOAD_0             => tb_LOAD_0,
		LOAD_A             => tb_LOAD_A,
		LFSR_DEBUG_OUT     => tb_LFSR_DEBUG_OUT,
		ALFSR_DEBUG_OUT    => tb_ALFSR_DEBUG_OUT,
		FA_DEBUG_OUT       => tb_FA_DEBUG_OUT,
		EDGE_DEBUG_OUT     => tb_EDGE_DEBUG_OUT,
		NET_DEBUG_OUT      => tb_NET_DEBUG_OUT,
		RESULTS_SERIAL_OUT => tb_RESULTS_SERIAL_OUT,
		VALID_DATA         => tb_VALID_DATA
	);
END test;