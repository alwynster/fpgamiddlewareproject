--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
-- use ieee.math_real.all;
use IEEE.NUMERIC_STD.all;

--library ieee_proposed;
--use ieee_proposed.fixed_float_types.all;
--use ieee_proposed.fixed_pkg.all;

package Common is

constant b                  :   natural := 16;

subtype fixed_point is unsigned(b-1 downto 0);

constant w 					: 	natural := 3;
constant l 					:	natural := 3;
constant eps				:	natural := 10;
constant factor				:	fixed_point := to_unsigned(1024, 16);
constant factor_2   		:	fixed_point := to_unsigned(512, 16);
--constant input_number		:	natural := 0;
--constant output_number		:	natural := 0;
    
-- subtype fixed_point is integer range -10000 to 10000;
type fixed_point_vector is array (w-1 downto 0) of fixed_point;
type fixed_point_matrix is array (w-1 downto 0) of fixed_point_vector;
type fixed_point_array is array (l-1 downto 0) of fixed_point_vector;

--function maximum_probability (signal probs_in : in fixed_point_vector) return fixed_point;
function weighted_sum (signal weights : fixed_point_vector; signal connections : fixed_point_vector) return fixed_point;
function sum (signal connections : fixed_point_vector) return fixed_point;
--function scale (signal weights : fixed_point_vector; const : real) return fixed_point_vector;
function "+" (A: in fixed_point_vector; B: in fixed_point_vector) return fixed_point_vector;
--function "+" (A: in fixed_point; B: in fixed_point) return fixed_point;
--function "*" (A: in fixed_point; B: in fixed_point) return fixed_point;
--function "-" (A: in fixed_point; B: in fixed_point) return fixed_point;
function "-" (A: in fixed_point_vector; B: in fixed_point_vector) return fixed_point_vector;
function "=" (A: in fixed_point_vector; B: in fixed_point_vector) return boolean;
--function "=" (A: in fixed_point; B: in fixed_point) return boolean;
function "=" (A: in fixed_point; B: in real) return boolean;
function "<=" (A: in fixed_point; B: in integer) return boolean;
function ">=" (A: in fixed_point; B: in integer) return boolean;
function "<" (A: in fixed_point; B: in integer) return boolean;
function ">" (A: in fixed_point; B: in integer) return boolean;
function "and" (A: fixed_point_vector; B: std_logic) return fixed_point_vector;
--function "*" (A: in fixed_point; B: in fixed_point) return fixed_point;
function real_to_fixed_point (A: in real) return fixed_point;
function logic_to_fixed_point (A: in std_logic) return fixed_point;
function resize_fixed_point (A : in fixed_point) return fixed_point;
function multiply(A : in fixed_point; B : in fixed_point) return fixed_point;
function round (A : in fixed_point) return std_logic;
--function exp(A: in fixed_point) return fixed_point;
--function sigmoid(arg : in fixed_point) return fixed_point;


end Common;

package body Common is

--	function maximum_probability (signal probs_in : in fixed_point_vector) return fixed_point is
--	variable max_i : natural := 0;
--	variable max : fixed_point := (others => '0');
--	begin
--		for i in 0 to probs_in'length loop
--			if (probs_in(i) > max) then
--				max := probs_in(i);
--				max_i := i;
--			end if;
--		end loop;
--		return max_i;
--	end maximum_probability;

	function weighted_sum (signal weights : fixed_point_vector; signal connections : fixed_point_vector) return fixed_point is
	variable sum : fixed_point := (others => '0');
	begin
		for i in 0 to w-1 loop
			-- sum := resize_fixed_point(sum + resize_fixed_point(weights(i) * connections(i)));
			-- scales to factor*factor
			sum := sum + multiply(weights(i), connections(i));
		end loop;
--		return sum / factor;
        return sum;
	end weighted_sum;

	function sum (signal connections : fixed_point_vector) return fixed_point is
	variable sum_var : fixed_point := (others => '0');
	begin
		for i in 0 to connections'length - 1 loop
			sum_var := sum_var + connections(i);
		end loop;
		return sum_var;
	end sum;

	function scale (signal weights : fixed_point_vector; const : fixed_point) return fixed_point_vector is
		variable scaled : fixed_point_vector;
	begin
		for i in 0 to weights'length - 1 loop
			scaled(i) := weights(i) * const;
		end loop;
		return scaled;
	end scale;

	function "+" (A: in fixed_point_vector; B: in fixed_point_vector) return fixed_point_vector is
	variable add : fixed_point_vector := (others => factor);
	begin
		for i in 0 to w-1 loop
			add(i) := A(i) + B(i);
		end loop;
		return add;
	end "+";

--	function "+" (A: in fixed_point; B: in fixed_point) return fixed_point is
--	begin
--		return A + B;
--	end "+";

--	function "*" (A: in fixed_point; B: in fixed_point) return fixed_point is
--	   variable TEMP : unsigned (fixed_point'length + fixed_point'high downto 0) := A * B;
--	begin 
--		return TEMP(25 downto 10);
--	end "*";

	--function "-" (A: in fixed_point; B: in fixed_point) return fixed_point is
	--variable add : fixed_point := 0;
	--begin
	--	add := A - B;
	--	return add;
	--end "-";

	function "-" (A: in fixed_point_vector; B: in fixed_point_vector) return fixed_point_vector is
	variable diff : fixed_point_vector := (others => factor);
	begin
		for i in 0 to w-1 loop
			diff(i) := A(i) - B(i);
		end loop;
		return diff;
	end "-";
	
	function "=" (A: in fixed_point_vector; B: in fixed_point_vector) return boolean is
	variable same : boolean := true;
	begin
		for i in 0 to w-1 loop
			if A(i) - B(i) > eps then
				same := false;
			end if;
		end loop;
		return same;
	end "=";

	function "=" (A: in fixed_point; B: in real) return boolean is
	begin
		if A - real_to_fixed_point(B) > eps then
			return false;
		else 
			return true;
		end if;
	end "=";

	function "<=" (A: in fixed_point; B: in integer) return boolean is
	begin
		if A <= to_unsigned(B, fixed_point'length) then
			return false;
		else 
			return true;
		end if;
	end "<=";

	function ">=" (A: in fixed_point; B: in integer) return boolean is
	begin
        if A >= to_unsigned(B, fixed_point'length) then
			return false;
		else 
			return true;
		end if;
	end ">=";

	function "<" (A: in fixed_point; B: in integer) return boolean is
	begin
		if A < to_unsigned(B, fixed_point'length) then
			return false;
		else 
			return true;
		end if;
	end "<";

	function ">" (A: in fixed_point; B: in integer) return boolean is
	begin
        if A > to_unsigned(B, fixed_point'length) then
			return false;
		else 
			return true;
		end if;
	end ">";

	--function "=" (A: in fixed_point; B: in fixed_point) return boolean is
	--begin
	--	if abs(A - B) > eps then
	--		return false;
	--	else 
	--		return true;
	--	end if;
	--end "=";

	function "and" (A: fixed_point_vector; B: std_logic) return fixed_point_vector is
	variable ret : fixed_point_vector := (others => factor);
	begin
		for i in 0 to w-1 loop
			if B = '1' then
				ret(i) := A(i);
			else
				ret(i) := (others => '0');
			end if;
		end loop;
		return ret;
	end "and";

	--function "*" (A: in fixed_point; B: in real) return fixed_point
	--begin
	--	return natural
	--end "*";

	function real_to_fixed_point (A: in real) return fixed_point is
		variable prob : fixed_point;
	begin
		if A = 0.0 then
			return (others => '0');
		elsif A = 1.0 then
			return factor;
		else 
			return factor_2;
		end if;
	end real_to_fixed_point;

	function logic_to_fixed_point (A: in std_logic) return fixed_point is
		variable prob : fixed_point;
	begin
		if A = '0' then
			return (others => '0');
		else 
			return factor;
		end if;
	end logic_to_fixed_point;

	function resize_fixed_point(A : in fixed_point) return fixed_point is
    begin
        return A / factor;
    end resize_fixed_point;

	function multiply(A : in fixed_point; B : in fixed_point) return fixed_point is
	   variable TEMP : unsigned (31 downto 0);
	   variable TEMP2 : unsigned (15 downto 0);
	begin
	   TEMP := A * B;
	   TEMP2 := TEMP(25 downto 10);
	   return TEMP2;
--		return TEMP(25 downto 10); -- take result and divide by factor ( >> 10 ) and cut off top
	end multiply;
    
    function round (A : in fixed_point) return std_logic is
        variable output : std_logic;
    begin
        if A < factor_2 then
            output := '0';
        else
            output := '1';
        end if;
            
        return output;
    end round;
        
	--function exp(A: in fixed_point) return fixed_point is
	--begin
	--	return to_fixed_point(1.0) + A + (A * A / 2.0) + (A * A * A / 6.0) + (A * A * A * A / 24.0);
	--end exp;
 	


end Common;