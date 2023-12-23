library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utils.all;

entity cordic is
    generic(N: natural := 16; N_CONT : natural := 4; ITERATIONS: natural := 15);
    port(x0 : in signed(N+1 downto 0);
        y0 : in signed(N+1 downto 0);
        z0 : in signed(N+1 downto 0);
        xr : out signed(N+1 downto 0);
        yr : out signed(N+1 downto 0);
        zr : out signed(N+1 downto 0);
        start : in std_logic;
        clk : in std_logic;
        mode : in std_logic
    );
end cordic;

architecture cordic_rolled_arch of cordic is
    signal i : natural;
    signal x_pre : signed(N+1 downto 0);
    signal y_pre : signed(N+1 downto 0);
    signal z_pre : signed(N+1 downto 0);
    signal x_in : signed(N+1 downto 0);
    signal y_in : signed(N+1 downto 0);
    signal z_in : signed(N+1 downto 0);
    signal x_act : signed(N+1 downto 0);
    signal y_act : signed(N+1 downto 0);
    signal z_act : signed(N+1 downto 0);
    signal x_next : signed(N+1 downto 0);
    signal y_next : signed(N+1 downto 0);
    signal z_next : signed(N+1 downto 0);
    constant betas: int_array(ITERATIONS-1 downto 0) := gen_atan_table(N+2, ITERATIONS);
    signal beta : signed(N+1 downto 0);
    signal count_en : std_logic;
    
begin
    --PRECORDIC
    PRECORDIC: entity work.precordic
    generic map(NP => N+2)
    port map(x_in => x0,
         y_in => y0,
         z_in => z0,
         x_out => x_pre,
         y_out => y_pre,
         z_out => z_pre,
         mode => mode
    );

     --CONTADOR
     COUNTER: entity work.counter
     generic map(MAX => (ITERATIONS-1))
     port map(
         clk => clk,
         ena => count_en,
         rst => start,
         count => i
     );
     --ETAPA CORDIC
     CORDIC_STAGE: entity work.cordic_stage
     generic map(NC => N+2)
    port map(x_in => x_in,
             y_in => y_in,
             z_in => z_in,
             x_out => x_next,
             y_out => y_next,
             z_out => z_next,
             beta => beta,
             shift => i,
             mode => mode
    );
    --REGISTROS A LA SALIDA
    REG_X: entity work.ffd
    generic map(NR => N+2)
    port map(rst => start,
             clk => clk,
             di => x_next,
             qo => x_act
    );
    REG_Y: entity work.ffd
    generic map(NR => N+2)
    port map(rst => start,
             clk => clk,
             di => y_next,
             qo => y_act
    );
    REG_Z: entity work.ffd
    generic map(NR => N+2)
    port map(rst => start,
             clk => clk,
             di => z_next,
             qo => z_act
    );

--Asignación de valor de beta
beta <= to_signed(betas(i), N+2) when count_en = '1' else (others => '0');

--Proceso principal
P_MAIN: process(clk, start, i)
begin
    --Detección de inicio
    if falling_edge(start) then
        count_en <= '1';
    end if;
    if i = 0 then
        x_in <= x_pre;
        y_in <= y_pre;
        z_in <= z_pre;
    else
        x_in <= x_act;
        y_in <= y_act;
        z_in <= z_act;
    end if;
    if i = ITERATIONS-1 then
        count_en <= '0';
    end if;
end process;

--Valores finales
xr <= x_act;
yr <= y_act;
zr <= z_act;

end cordic_rolled_arch;

architecture cordic_unrolled_arch of cordic is
    type array_of_signed is array(natural range <>) of signed(N+1 downto 0);

    signal x_pre : signed(N+1 downto 0);
    signal y_pre : signed(N+1 downto 0);
    signal z_pre : signed(N+1 downto 0);
    signal x_i: array_of_signed(ITERATIONS downto 0);
    signal y_i: array_of_signed(ITERATIONS downto 0);
    signal z_i: array_of_signed(ITERATIONS downto 0);
    signal x_o: array_of_signed(ITERATIONS downto 0);
    signal y_o: array_of_signed(ITERATIONS downto 0);
    signal z_o: array_of_signed(ITERATIONS downto 0);

    constant betas: int_array(ITERATIONS-1 downto 0) := gen_atan_table(N+2, ITERATIONS);

    signal mode_vec : std_logic_vector(ITERATIONS downto 0);

    --COMPONENTES
    --Etapa cordic
    component cordic_stage
        generic(NC : natural);
        port(x_in : in signed(NC-1 downto 0);
            y_in : in signed(NC-1 downto 0);
            z_in : in signed(NC-1 downto 0);
            x_out : out signed(NC-1 downto 0);
            y_out : out signed(NC-1 downto 0);
            z_out : out signed(NC-1 downto 0);
            beta : in signed(NC-1 downto 0);
            shift : in integer;
            mode : in std_logic --Modo de operacion (rotación => '1', vector => '0')
        );
    end component;
    --Registros
    component ffd
    generic(NR: natural);
    port(
        di : in signed(NR-1 downto 0);
        qo : out signed(NR-1 downto 0);
        clk : in std_logic;
        rst : in std_logic
    );
    end component;

begin
    --Asignaciones
    --Señales de entrada
    x_i(0) <= x_pre;
    y_i(0) <= y_pre;
    z_i(0) <= z_pre;
    --Señales de salida
    xr <= x_i(ITERATIONS);
    yr <= y_i(ITERATIONS);
    zr <= z_i(ITERATIONS);
    --Modo de primera etapa
    mode_vec(0) <= mode;

    --PRECORDIC
    PRECORDIC: entity work.precordic
    generic map(NP => N+2)
    port map(x_in => x0,
         y_in => y0,
         z_in => z0,
         x_out => x_pre,
         y_out => y_pre,
         z_out => z_pre,
         mode => mode
    );

    COMPONENTS: for i in 0 to ITERATIONS-1 generate
        CORDIC_STAGE_INST: cordic_stage
        generic map(NC => N+2)
        port map(x_in => x_i(i),
                 y_in => y_i(i),
                 z_in => z_i(i),
                 x_out => x_o(i),
                 y_out => y_o(i),
                 z_out => z_o(i),
                 beta => to_signed(betas(i), N+2),
                 shift => i,
                 mode => mode_vec(i)
        );

        REG_X_INST: ffd
        generic map(NR => N+2)
        port map(rst => start,
                 clk => clk,
                 di => x_o(i),
                 qo => x_i(i+1)
        );

        REG_Y_INST: ffd
        generic map(NR => N+2)
        port map(rst => start,
                 clk => clk,
                 di => y_o(i),
                 qo => y_i(i+1)
        );

        REG_Z_INST: ffd
        generic map(NR => N+2)
        port map(rst => start,
                 clk => clk,
                 di => z_o(i),
                 qo => z_i(i+1)
        );

    end generate;

    --Proceso que va despalazando el modo a través de las estapas
    P_MODE_REG: process(start, clk)
        begin
        if start = '1' then
            mode_vec(ITERATIONS downto 1) <= (others => '0');
        end if;
        if rising_edge(clk) then
               mode_vec(ITERATIONS downto 1) <= mode_vec(ITERATIONS-1 downto 0);
        end if;
    end process;
end cordic_unrolled_arch;