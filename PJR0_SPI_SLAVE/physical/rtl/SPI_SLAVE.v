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
module SPI_SLAVE #(parameter DATAWIDTH_BUS = 8, parameter STATE_SIZE = 3)(
//////////// OUTPUTS ////////////
	SPI_SLAVE_MISO_Out,
	SPI_SLAVE_newData_Out,
	SPI_SLAVE_data_Out,
//////////// INPUTS ////////////
	SPI_SLAVE_CLOCK_50,
	SPI_SLAVE_RESET_InHigh,
	SPI_SLAVE_SS_InLow,
	SPI_SLAVE_MOSI_In,
	SPI_SLAVE_SCK_In,
	SPI_SLAVE_data_In
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
//////////// STATES ////////////
localparam		State_IDLE = 3'b000;
localparam		State_EDGE = 3'b001;
localparam		State_RISE_EDGE = 3'b010;
localparam		State_NEW_DATA = 3'b011;
localparam		State_FALL_EDGE = 3'b100;
//////////// SIZES ////////////

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	SPI_SLAVE_MISO_Out;
output	SPI_SLAVE_newData_Out;
output	[DATAWIDTH_BUS-1:0] SPI_SLAVE_data_Out;
//////////// INPUTS ////////////
input 	SPI_SLAVE_CLOCK_50;
input 	SPI_SLAVE_RESET_InHigh;
input		SPI_SLAVE_SS_InLow;
input		SPI_SLAVE_MOSI_In;
input		SPI_SLAVE_SCK_In;
input		[DATAWIDTH_BUS-1:0] SPI_SLAVE_data_In;
//////////// FLAGS ////////////

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================
//////////// REGISTERS ////////////
// Master Input Slave Output data transmitter 
reg MISO_Register;
// Boolean variable to inform of new data
reg NewData_Register;
// Byte size register with the data to send to the master
reg [DATAWIDTH_BUS-1:0] DataOut_Register;
// Current state of the protocol
reg [STATE_SIZE-1:0] State_Register;
// Shift Slave variable that points out if the master allows data transmission
reg SS_Register;
// Master Output Slave Input data transmitter
reg MOSI_Register;
// Clock signal that synchronizes the Master and Slave modules
reg SCK_Register;
// Value inmediately prior to SCK signal
reg SCKOld_Register;
// Data in terms of bytes comming from the master 
reg [DATAWIDTH_BUS-1:0] Data_Register;
// Counter for the number of bits carried out so far
reg [2:0] BitCounter_Register;
//////////// SIGNALS ////////////
reg MISO_Signal;
reg NewData_Signal;
reg [DATAWIDTH_BUS-1:0] DataOut_Signal;
reg [STATE_SIZE-1:0] State_Signal;
reg SS_Signal;
reg MOSI_Signal;
reg SCK_Signal;
reg SCKOld_Signal;
reg [DATAWIDTH_BUS-1:0] Data_Signal;
reg [2:0] BitCounter_Signal;

//===========================================================================
//  STRUCTURAL Coding
//===========================================================================
// INPUT LOGIC: Combinational
always @(*)
	begin
		// To init registers
		MOSI_Signal = SPI_SLAVE_MOSI_In;
		SS_Signal = SPI_SLAVE_SS_InLow;
		SCK_Signal = SPI_SLAVE_SCK_In;
		SCKOld_Signal = SCK_Register;
		Data_Signal = Data_Register;
		BitCounter_Signal = BitCounter_Register;
		
		case (State_Register)
			State_IDLE:
				begin
					if (SS_Register)
						begin
							State_Signal = State_IDLE;
							BitCounter_Signal = 3'b000;
							Data_Signal = SPI_SLAVE_data_In;
						end
					else
						State_Signal = State_EDGE;
				end
					
			State_EDGE:
				begin
					if (!SCKOld_Register && SCK_Register)
						State_Signal = State_RISE_EDGE;
					else if (SCKOld_Register && !SCK_Register)
						State_Signal = State_FALL_EDGE;
					else
						State_Signal = State_EDGE;
				end
					
			State_RISE_EDGE:
				begin
					BitCounter_Signal = BitCounter_Register + 1'b1;
					Data_Signal = {Data_Register[6:0],MOSI_Register};
					if (BitCounter_Register == DATAWIDTH_BUS-1)
						State_Signal = State_NEW_DATA;
					else
						State_Signal = State_EDGE;
				end
				
			State_NEW_DATA:
				begin
					State_Signal = State_EDGE;
					BitCounter_Signal = 3'b000;
					Data_Signal = SPI_SLAVE_data_In;
				end
			
			State_FALL_EDGE:
				begin
					if (SS_Register)
						State_Signal = State_IDLE;
					else
						State_Signal = State_EDGE;
				end
				
			default: State_Signal = State_IDLE;
		endcase
	end
	
// STATE REGISTER : Sequential
always @(posedge SPI_SLAVE_CLOCK_50, posedge SPI_SLAVE_RESET_InHigh)
	begin
		if (SPI_SLAVE_RESET_InHigh)
			begin
				MISO_Register <= 1'b1;
				NewData_Register <= 1'b0;
				DataOut_Register <= {DATAWIDTH_BUS{1'b0}};
				State_Register <= State_IDLE;
				SS_Register <= 1'b1;
				MOSI_Register <= 1'b1;
				SCK_Register <= 1'b0;
				SCKOld_Register <= 1'b0;
				Data_Register <= {DATAWIDTH_BUS{1'b0}};
				BitCounter_Register <= 3'b000;
			end
			
		else
			begin
				MISO_Register <= MISO_Signal;
				NewData_Register <= NewData_Signal;
				DataOut_Register <= DataOut_Signal;
				State_Register <= State_Signal;
				SS_Register <= SS_Signal;
				MOSI_Register <= MOSI_Signal;
				SCK_Register <= SCK_Signal;
				SCKOld_Register <= SCKOld_Signal;
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
		//MISO_Signal = MISO_Register;
		//NewData_Signal = NewData_Register;
		//DataOut_Signal = DataOut_Register;

		case (State_Register)
			State_IDLE:
				begin
					MISO_Signal = Data_Register[7];
					NewData_Signal = 1'b0;
					DataOut_Signal = DataOut_Register;
				end
			
			State_EDGE: 
				begin
					MISO_Signal = MISO_Register;
					NewData_Signal = 1'b0;
					DataOut_Signal = DataOut_Register;
				end
				
			State_RISE_EDGE:		
				begin
					MISO_Signal = MISO_Register;
					NewData_Signal = 1'b0;
					DataOut_Signal = DataOut_Register;
				end
				
			State_NEW_DATA:		
				begin
					MISO_Signal = MISO_Register;
					NewData_Signal = 1'b1;
					DataOut_Signal = Data_Register;
				end
				
			State_FALL_EDGE:
				begin		
					MISO_Signal = Data_Register[7];
					NewData_Signal = 1'b0;
					DataOut_Signal = DataOut_Register;
				end

			default:
				begin
					MISO_Signal = 1'b1;
					NewData_Signal = 1'b0;
					DataOut_Signal = DataOut_Register;
				end
		endcase
	end
	
// OUTPUT ASSIGNMENTS
assign SPI_SLAVE_MISO_Out = MISO_Register;
assign SPI_SLAVE_newData_Out = NewData_Register;
assign SPI_SLAVE_data_Out = DataOut_Register;

endmodule
