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
         z_out : out signed(NP-1 downto 0)
    );
end precordic;

architecture precordic_arch of precordic is
    signal x_in_2c : signed(NP-1 downto 0);
    signal y_in_2c : signed(NP-1 downto 0);
    signal z_in_inv : signed(NP-1 downto 0);

    begin
        x_in_2c <= not(x_in) + 1;
        y_in_2c <= not(y_in) + 1;
        z_in_inv(NP-1) <= not z_in(NP-1);
        z_in_inv(NP-2 downto 0) <= z_in(NP-2 downto 0);

        x_out <= x_in when z_in(NP-2) = '0' else x_in_2c;
        y_out <= y_in when z_in(NP-2) = '0' else y_in_2c;
        z_out <= z_in when z_in(NP-2) = '0' else z_in_inv;
end precordic_arch;