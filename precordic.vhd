library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity precordic is
    generic(NP : natural := 16);
    port(x_in : in signed(NP-1 downto 0);
         y_in : in signed(NP-1 downto 0);
         z_in : in signed(NP-1 downto 0);
         x_out : out signed(NP-1 downto 0);
         y_out : out signed(NP-1 downto 0);
         z_out : out signed(NP-1 downto 0);
         mode : in std_logic
    );
end precordic;

architecture precordic_arch of precordic is
    signal x_in_2c : signed(NP-1 downto 0);
    signal y_in_2c : signed(NP-1 downto 0);
    signal z_in_inv : signed(NP-1 downto 0);
    signal x_rot : signed(NP-1 downto 0);
    signal y_rot : signed(NP-1 downto 0);
    signal z_rot : signed(NP-1 downto 0);
    signal x_vec : signed(NP-1 downto 0);
    signal y_vec : signed(NP-1 downto 0);
    signal z_vec : signed(NP-1 downto 0);

    begin
        x_in_2c <= not(x_in) + 1; --Complemento a 2
        y_in_2c <= not(y_in) + 1; --Complemento a 2
        --z_in + o - 180°
        z_in_inv(NP-1) <= not z_in(NP-1);
        z_in_inv(NP-2 downto 0) <= z_in(NP-2 downto 0);

        --Modo rotación, ángulos entre 90° y 180° o angulos entre 180° y 270°
        x_rot <= x_in_2c when (z_in(NP-1) = '0' and z_in(NP-2) = '1') or (z_in(NP-1) = '1' and z_in(NP-2) = '0')  else x_in;
        y_rot <= y_in_2c when (z_in(NP-1) = '0' and z_in(NP-2) = '1') or (z_in(NP-1) = '1' and z_in(NP-2) = '0') else y_in; 
        z_rot <= z_in_inv when (z_in(NP-1) = '0' and z_in(NP-2) = '1') or (z_in(NP-1) = '1' and z_in(NP-2) = '0') else z_in; 

        --Modo vector
        x_vec <= x_in_2c when x_in(NP-1) = '1' else x_in;
        y_vec <= y_in_2c when x_in(NP-1) = '1' else y_in; 
        z_vec <= z_in_inv when x_in(NP-1) = '1' else z_in; 

        --Salidas (dependen del modo vector = '1' , rotación = '0')
        x_out <= x_vec when mode = '1' else x_rot;
        y_out <= y_vec when mode = '1' else y_rot;
        z_out <= z_vec when mode = '1' else z_rot;
end precordic_arch;