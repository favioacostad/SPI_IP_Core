/*###########################################################################
//# G0B1T: HDL SERIAL COMMUNICATION PROTOCOLS. 2020.
//###########################################################################
//# Copyright (C) 2018. F.E.Segura Quijano (FES) fsegura@uniandes.edu.co
//# Copyright (C) 2020. F.A.Acosta David   (FAD) fa.acostad@uniandes.edu.co
//# 
//# This program is free software: you can redistribute it and/or modify
//# it under the terms of the GNU General Public License as published by
//# the Free Software Foundation, version 3 of the License.
//#
//# This program is distributed in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//# GNU General Public License for more details.
//#
//# You should have received a copy of the GNU General Public License
//# along with this program.  If not, see <http://www.gnu.org/licenses/>
//#########################################################################*/

//===========================================================================
//  MODULE Definition
//===========================================================================
module BB_SYSTEM (
//////////// OUTPUTS ////////////
	BB_SYSTEM_MOSI_Out,
	BB_SYSTEM_newData_Out,
	BB_SYSTEM_SCK_Out,
	BB_SYSTEM_data_Out,
	BB_SYSTEM_dataCounter_Out,
//////////// INPUTS ////////////
	BB_SYSTEM_CLOCK_50,
	BB_SYSTEM_RESET_InHigh,
	BB_SYSTEM_COUNT_InHigh,
	BB_SYSTEM_MISO_In
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
// Data width of the imput bus
parameter DATAWIDTH_BUS = 8;
// Size for the states needed into the protocol
parameter STATE_SIZE = 3;
// Value to specify how much be the clock for synchronizing Master and Slave
parameter CLOCK_RATIO = 4;

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	BB_SYSTEM_MOSI_Out;
output	BB_SYSTEM_newData_Out;
output	BB_SYSTEM_SCK_Out;
output	[DATAWIDTH_BUS-1:0] BB_SYSTEM_data_Out;
output	[DATAWIDTH_BUS-1:0] BB_SYSTEM_dataCounter_Out;
//////////// INPUTS ////////////
input		BB_SYSTEM_CLOCK_50;
input		BB_SYSTEM_RESET_InHigh;
input		BB_SYSTEM_COUNT_InHigh;
input		BB_SYSTEM_MISO_In;

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================
// Boolean variable to indicate if the module UART_TX is currently busy or idle
wire SPI_MASTER_2_PULSE_COUNTER_busy_wire;
// Boolean variable to inform SPI_MASTER of new data to send
wire PULSE_COUNTER_2_SPI_MASTER_start_wire;
// Data in terms of bytes to transmit
wire [DATAWIDTH_BUS-1:0] PULSE_COUNTER_2_SPI_MASTER_data_wire;

//===========================================================================
//  STRUCTURAL Coding
//===========================================================================
SPI_MASTER #(.CLOCK_RATIO(CLOCK_RATIO), .DATAWIDTH_BUS(DATAWIDTH_BUS), .STATE_SIZE(STATE_SIZE)) SPI_MASTER_u0 (
// Port map - connection between master ports and signals/registers  
//////////// OUTPUTS ////////////
	.SPI_MASTER_MOSI_Out(BB_SYSTEM_MOSI_Out),
	.SPI_MASTER_newData_Out(BB_SYSTEM_newData_Out),
	.SPI_MASTER_busy_Out(SPI_MASTER_2_PULSE_COUNTER_busy_wire),
	.SPI_MASTER_SCK_Out(BB_SYSTEM_SCK_Out),
	.SPI_MASTER_data_Out(BB_SYSTEM_data_Out),
//////////// INPUTS ////////////
	.SPI_MASTER_CLOCK_50(BB_SYSTEM_CLOCK_50),
	.SPI_MASTER_RESET_InHigh(BB_SYSTEM_RESET_InHigh),
	.SPI_MASTER_MISO_In(BB_SYSTEM_MISO_In),
	.SPI_MASTER_start_InHigh(PULSE_COUNTER_2_SPI_MASTER_start_wire),
	.SPI_MASTER_data_In(PULSE_COUNTER_2_SPI_MASTER_data_wire)
);

PULSE_COUNTER #(.DATAWIDTH_BUS(DATAWIDTH_BUS), .STATE_SIZE(STATE_SIZE)) PULSE_COUNTER_u0 (
// Port map - connection between master ports and signals/registers  
//////////// OUTPUTS ////////////
	.PULSE_COUNTER_start_Out(PULSE_COUNTER_2_SPI_MASTER_start_wire),
	.PULSE_COUNTER_data_Out(PULSE_COUNTER_2_SPI_MASTER_data_wire),
	.PULSE_COUNTER_dataCounter_Out(BB_SYSTEM_dataCounter_Out),
//////////// INPUTS ////////////
	.PULSE_COUNTER_CLOCK_50(BB_SYSTEM_CLOCK_50),
	.PULSE_COUNTER_RESET_InHigh(BB_SYSTEM_RESET_InHigh),
	.PULSE_COUNTER_COUNT_InHigh(BB_SYSTEM_COUNT_InHigh),
	.PULSE_COUNTER_masterBusy_InHigh(SPI_MASTER_2_PULSE_COUNTER_busy_wire)
);

endmodule
