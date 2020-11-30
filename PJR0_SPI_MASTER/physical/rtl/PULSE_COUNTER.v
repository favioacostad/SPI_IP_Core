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
module PULSE_COUNTER #(parameter DATAWIDTH_BUS = 8, parameter STATE_SIZE = 3)(
//////////// OUTPUTS ////////////
	PULSE_COUNTER_start_Out,
	PULSE_COUNTER_data_Out,
	PULSE_COUNTER_dataCounter_Out,
//////////// INPUTS ////////////
	PULSE_COUNTER_CLOCK_50,
	PULSE_COUNTER_RESET_InHigh,
	PULSE_COUNTER_COUNT_InHigh,
	PULSE_COUNTER_masterBusy_InHigh
);

//===========================================================================
//  PARAMETER Declarations
//===========================================================================
//////////// STATES ////////////
localparam		State_START = 3'b000;
localparam		State_IDLE = 3'b001;
localparam		State_LOAD = 3'b010;
localparam		State_COUNT = 3'b011;

//////////// SIZES ////////////

//===========================================================================
//  PORT Declarations
//===========================================================================
//////////// OUTPUTS ////////////
output	PULSE_COUNTER_start_Out;
output	[DATAWIDTH_BUS-1:0] PULSE_COUNTER_data_Out;
output	[DATAWIDTH_BUS-1:0] PULSE_COUNTER_dataCounter_Out;
//////////// INPUTS ////////////
input		PULSE_COUNTER_CLOCK_50;
input 	PULSE_COUNTER_RESET_InHigh;
input		PULSE_COUNTER_COUNT_InHigh;
input		PULSE_COUNTER_masterBusy_InHigh;
//////////// FLAGS ////////////

//===========================================================================
//  REG/WIRE Declarations
//===========================================================================
//////////// REGISTERS ////////////
// Boolean variable to inform of new data
reg Start_Register;
// Data in terms of bytes 
reg [DATAWIDTH_BUS-1:0] Data_Register;
// Current state of the protocol
reg [STATE_SIZE-1:0] State_Register;

//////////// SIGNALS ////////////
reg Start_Signal;
reg [DATAWIDTH_BUS-1:0] Data_Signal;
reg [STATE_SIZE-1:0] State_Signal;

//===========================================================================
//  STRUCTURAL Coding
//===========================================================================
// INPUT LOGIC: Combinational
always @(*)
	begin
		case(State_Register)
			State_START:
				State_Signal = State_IDLE;
					
			State_IDLE:
				if (~PULSE_COUNTER_COUNT_InHigh)
					State_Signal = State_LOAD;
				else
					State_Signal = State_IDLE;
			
			State_LOAD:
				if (PULSE_COUNTER_COUNT_InHigh)
					State_Signal = State_COUNT;
				else
					State_Signal = State_LOAD;
					
			State_COUNT:
				if (~PULSE_COUNTER_COUNT_InHigh & ~PULSE_COUNTER_masterBusy_InHigh)
					State_Signal = State_IDLE;
				else
					State_Signal = State_START;
			
			default: State_Signal = State_START;
		endcase
	end

// STATE REGISTER : Sequential
always @(posedge PULSE_COUNTER_CLOCK_50, posedge PULSE_COUNTER_RESET_InHigh)
	begin
		if (PULSE_COUNTER_RESET_InHigh)
			begin
				Start_Register <= 1'b0;
				Data_Register <= {DATAWIDTH_BUS{1'b0}};
				State_Register <= State_START;
			end
		
		else
			begin
				Start_Register <= Start_Signal;
				Data_Register <= Data_Signal;
				State_Register <= State_Signal;
			end
	end

//===========================================================================
//  OUTPUTS
//===========================================================================
// OUTPUT LOGIC: Combinational
always @(*)
	begin
		case(State_Register)
			State_START:
				begin
					Start_Signal = 1'b0;
					Data_Signal = Data_Register;
				end
				
			State_IDLE:
				begin
					Start_Signal = 1'b0;
					Data_Signal = Data_Register;
				end

			State_LOAD:
				begin
					Start_Signal = 1'b0;
					Data_Signal = Data_Register;
				end
					
			State_COUNT:
				begin
					Start_Signal = 1'b1;
					Data_Signal = Data_Register + 8'b00000001;
				end
				
			default:
				begin
					Start_Signal = 1'b0;
					Data_Signal = Data_Register;
				end
				
		endcase
	end
	
// OUTPUT ASSIGNMENTS
assign PULSE_COUNTER_start_Out = Start_Register;
assign PULSE_COUNTER_data_Out = Data_Register;
assign PULSE_COUNTER_dataCounter_Out = Data_Register;

endmodule
