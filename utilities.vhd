library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

package utils is
    type int_array is array (natural range <>) of integer;

    function gen_atan_table(size : natural; iterations : natural) return int_array;
    function shift_right(reg : signed; shift : natural) return signed;

end utils;

package body utils is

    function gen_atan_table(size : natural; iterations : natural) return int_array is
        variable table : int_array(iterations-1 downto 0);
      begin
        for i in table'range loop
          table(i) := integer(arctan(2.0**(-i)) * 2.0**size / MATH_2_PI);
        end loop;
        return table;
    end function;

    function shift_right(reg : signed; shift : natural) return signed is
        variable aux : signed(reg'range) := (others => '0');
    begin
        for i in (reg'length - 1) downto shift loop
            aux(i) := '0'; 
        end loop;
        for i in (shift - 1) downto 0 loop
            aux(i) := reg(i+shift); 
        end loop;
        return aux;
    end function;
end utils;