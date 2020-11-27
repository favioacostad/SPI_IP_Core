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
module SPI_MASTER #(parameter CLOCK_RATIO= 4, parameter DATAWIDTH_BUS = 8, parameter STATE_SIZE = 3)(
//////////// OUTPUTS ////////////
	SPI_MASTER_MOSI_Out,
	SPI_MASTER_newData_Out,
	SPI_MASTER_busy_Out,
	SPI_MASTER_SCK_Out,
	SPI_MASTER_data_Out,
//////////// INPUTS ////////////
	SPI_MASTER_CLOCK_50,
	SPI_MASTER_RESET_InHigh,
	SPI_MASTER_MISO_In,
	SPI_MASTER_start_InHigh,
	SPI_MASTER_data_In
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
//////////// STATES ////////////
localparam		State_IDLE = 3'b000;
localparam		State_WAIT_HALF = 3'b001;
localparam		State_TRANSFER = 3'b010;	
localparam		State_MOSI = 3'b011;	
localparam		State_READ_DATA = 3'b100;	
localparam		State_FULL = 3'b101;	
localparam		State_END = 3'b110;
//////////// SIZES ////////////

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	SPI_MASTER_MOSI_Out;
output	SPI_MASTER_newData_Out;
output	SPI_MASTER_busy_Out;
output	SPI_MASTER_SCK_Out;
output	[DATAWIDTH_BUS-1:0] SPI_MASTER_data_Out;
//////////// INPUTS ////////////
input		SPI_MASTER_CLOCK_50;
input		SPI_MASTER_RESET_InHigh;
input		SPI_MASTER_MISO_In;
input		SPI_MASTER_start_InHigh;
input		[DATAWIDTH_BUS-1:0] SPI_MASTER_data_In;
//////////// FLAGS ////////////

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================
//////////// REGISTERS ////////////
// Master Output Slave Input data transmitter
reg MOSI_Register;
// Boolean variable to inform of new data
reg NewData_Register;
// Boolean variable to indicate if the module is currently busy or idle
reg Busy_Register;
// Clock signal that synchronizes the Master and Slave modules
reg [CLOCK_RATIO-1:0] SCK_Register;
// Byte size register with the data to send to the master
reg [DATAWIDTH_BUS-1:0] DataOut_Register;
// Current state of the protocol
reg [STATE_SIZE-1:0] State_Register;
// Master Input Slave Output data transmitter 
reg MISO_Register;
// Boolean variable to allow the module to start
reg Start_Register;
// Data in terms of bytes comming from the master 
reg [DATAWIDTH_BUS-1:0] Data_Register;
// Counter for the number of bits carried out so far
reg [2:0] BitCounter_Register;
//////////// SIGNALS ////////////
reg MOSI_Signal;
reg NewData_Signal;
reg Busy_Signal;
reg [CLOCK_RATIO-1:0] SCK_Signal;
reg [DATAWIDTH_BUS-1:0] DataOut_Signal;
reg [STATE_SIZE-1:0] State_Signal;
reg MISO_Signal;
reg Start_Signal; 
reg [DATAWIDTH_BUS-1:0] Data_Signal;
reg [2:0] BitCounter_Signal;

//===========================================================================
//  STRUCTURAL Coding
//===========================================================================
// INPUT LOGIC: Combinational
always @(*)
	begin
		// To init registers
		MISO_Signal = SPI_MASTER_MISO_In;
		Start_Signal = SPI_MASTER_start_InHigh;
		Data_Signal = Data_Register;
		BitCounter_Signal = BitCounter_Register;
		
		case (State_Register)
			State_IDLE: 
				begin 
					BitCounter_Signal = 3'b000;
					if (Start_Register)
						State_Signal = State_WAIT_HALF;
					else 
						State_Signal = State_IDLE;
				end
			
			State_WAIT_HALF:
				begin
					Data_Signal = SPI_MASTER_data_In;
					if (SCK_Register == {(CLOCK_RATIO-1){1'b1}})
						State_Signal = State_TRANSFER;
					else
						State_Signal = State_WAIT_HALF;
				end
				
			State_TRANSFER:
				begin
					if (SCK_Register == {CLOCK_RATIO{1'b0}})
						State_Signal = State_MOSI;
					else if (SCK_Register == {(CLOCK_RATIO-1){1'b1}})
						State_Signal = State_READ_DATA;
					else if (SCK_Register == {CLOCK_RATIO{1'b1}})
						State_Signal = State_FULL;
					else
						State_Signal = State_TRANSFER;
				end
				
			State_MOSI:
				State_Signal = State_TRANSFER;
				
			State_READ_DATA:
				begin
					State_Signal = State_TRANSFER;
					Data_Signal = {Data_Register[6:0],MISO_Register};
				end
				
			State_FULL:
				begin
					BitCounter_Signal = BitCounter_Register + 1'b1;
					if (BitCounter_Register == DATAWIDTH_BUS-1)
						State_Signal = State_END;
					else
						State_Signal = State_TRANSFER;
				end
				
			State_END:
				begin
					State_Signal = State_IDLE;
					BitCounter_Signal = 3'b000;
				end
				
			default: State_Signal = State_IDLE;
		endcase
	end
	
// STATE REGISTER : Sequential
always @(posedge SPI_MASTER_CLOCK_50, posedge SPI_MASTER_RESET_InHigh)
	begin
		if (SPI_MASTER_RESET_InHigh)
			begin
				MOSI_Register <= 1'b1;
				NewData_Register <= 1'b0;
				Busy_Register <= 1'b0;
				SCK_Register <= {CLOCK_RATIO{1'b0}};
				DataOut_Register <= {DATAWIDTH_BUS{1'b0}};
				State_Register <= State_IDLE;
				MISO_Register <= 1'b1;
				Start_Register <= 1'b0;
				Data_Register <= {DATAWIDTH_BUS{1'b0}};
				BitCounter_Register <= 3'b000;
			end
			
		else
			begin
				MOSI_Register <= MOSI_Signal;
				NewData_Register <= NewData_Signal;
				Busy_Register <= Busy_Signal;
				SCK_Register <= SCK_Signal;
				DataOut_Register <= DataOut_Signal;
				State_Register <= State_Signal;
				MISO_Register <= MISO_Signal;
				Start_Register <= Start_Signal;
				Data_Register <= Data_Signal;
				BitCounter_Register <= BitCounter_Signal;
			end
	end
	
//===========================================================================
//  OUTPUTS
//===========================================================================
// OUTPUT LOGIC: Combinational
always @(*)
	begin
		// To init registers

		case (State_Register)
			State_IDLE:
				begin
					MOSI_Signal = 1'b1;
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b0;
					SCK_Signal = {CLOCK_RATIO{1'b0}};
					DataOut_Signal = DataOut_Register;
				end
				
			State_WAIT_HALF:
				begin
					MOSI_Signal = MOSI_Register;
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b0;
					SCK_Signal = SCK_Register + 1'b1;
					if (SCK_Register == {(CLOCK_RATIO-1){1'b1}})
						SCK_Signal = {CLOCK_RATIO{1'b0}};
					DataOut_Signal = DataOut_Register;
				end
			
			State_TRANSFER:
				begin
					MOSI_Signal = MOSI_Register;
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b1;
					SCK_Signal = SCK_Register + 1'b1;
					DataOut_Signal = DataOut_Register;
				end
				
			State_MOSI:
				begin
					MOSI_Signal = Data_Register[7];
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b1;
					SCK_Signal = SCK_Register + 1'b1;
					DataOut_Signal = DataOut_Register;
				end
				
			State_READ_DATA:
				begin
					MOSI_Signal = MOSI_Register;
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b1;
					SCK_Signal = SCK_Register + 1'b1;
					DataOut_Signal = DataOut_Register;
				end
				
			State_FULL:
				begin
					MOSI_Signal = MOSI_Register;
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b0;
					SCK_Signal = SCK_Register;
					DataOut_Signal = DataOut_Register;
				end
				
			State_END:
				begin
					MOSI_Signal = MOSI_Register;
					NewData_Signal = 1'b1;
					Busy_Signal = 1'b0;
					SCK_Signal = SCK_Register;
					DataOut_Signal = Data_Register;
				end
			
			default:
				begin
					MOSI_Signal = 1'b1;
					NewData_Signal = 1'b0;
					Busy_Signal = 1'b0;
					SCK_Signal = {CLOCK_RATIO{1'b0}};
					DataOut_Signal = DataOut_Register;
				end
		endcase
	end
	
// OUTPUT ASSIGNMENTS
assign SPI_MASTER_MOSI_Out = MOSI_Register;
assign SPI_MASTER_newData_Out = NewData_Register;
assign SPI_MASTER_busy_Out = Busy_Register;
assign SPI_MASTER_SCK_Out = ~((~SCK_Register[CLOCK_RATIO-1]) & ((State_Register == State_TRANSFER) | (State_Register == State_MOSI) | (State_Register == State_READ_DATA) | (State_Register == State_FULL) | (State_Register == State_END)));
assign SPI_MASTER_data_Out = DataOut_Register;

endmodule
