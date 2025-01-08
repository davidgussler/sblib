-- (c) Copyright 1995-2016 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity PRBS is
    port(TxDATA     :out STD_LOGIC;
         RESET      :in STD_LOGIC;
         TxCLK      :in STD_LOGIC;
         RXCLK      :in STD_LOGIC;
         DATA       :in STD_LOGIC_VECTOR(2 downto 0);
         DATA_VALID :in STD_LOGIC_VECTOR(2 downto 0);
         ERROR      :out STD_LOGIC
         ); 
end PRBS;

architecture arch of PRBS is

  signal TxDATA_i   :UNSIGNED(31 downto 0):=(others=>'1');
  signal OCLK       :STD_LOGIC;
  signal OLD_DATA   :STD_LOGIC:='0';
  signal RxDATA     :UNSIGNED(31 downto 0):=(others=>'0');
begin


  process(TxCLK)
  begin
    if rising_edge (TxCLK) then
        if RESET = '1' then
            TxDATA_i <= (others =>'1');
        else
            TxDATA_i<=TxDATA_i(30 downto 0)&(TxDATA_i(31) xor TxDATA_i(21) xor TxDATA_i(1) xor TxDATA_i(0));
        end if;
    end if;
  end process;
  TxDATA <= TxDATA_i(0);
  
-- check for errors
  process(RXCLK)
    variable COUNT:INTEGER;
    variable NEWDATA:UNSIGNED(31 downto 0);
    variable ERR:STD_LOGIC;
  begin
    if rising_edge(RXCLK) then
      case DATA_VALID is
        when "001"=>COUNT:=1;
        when "011"=>COUNT:=2;
        when "111"=>COUNT:=3;
        when others=>COUNT:=0;
      end case;
      NEWDATA:=RxDATA;
      ERR:='0';
      if COUNT=0 then
      else
          if COUNT=1 then
            for K in 1-1 downto 0 loop
              ERR:=ERR or (NEWDATA(31) xor NEWDATA(21) xor NEWDATA(1) xor NEWDATA(0) xor DATA(K));
              NEWDATA:=NEWDATA(30 downto 0)&DATA(K);
            end loop;
          end if;
          if COUNT=2 then
            for K in 2-1 downto 0 loop
              ERR:=ERR or (NEWDATA(31) xor NEWDATA(21) xor NEWDATA(1) xor NEWDATA(0) xor DATA(K));
              NEWDATA:=NEWDATA(30 downto 0)&DATA(K);
            end loop;
          end if; 
          if COUNT=3 then
            for K in 3-1 downto 0 loop
              ERR:=ERR or (NEWDATA(31) xor NEWDATA(21) xor NEWDATA(1) xor NEWDATA(0) xor DATA(K));
              NEWDATA:=NEWDATA(30 downto 0)&DATA(K);
            end loop;
          end if;
      end if;
      RxDATA<=NEWDATA;
      ERROR<=ERR;
    end if;
  end process;
end arch;