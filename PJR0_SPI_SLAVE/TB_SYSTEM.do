onerror {resume}
quietly WaveActivateNextPane {} 0
delete wave *
add wave -noupdate /TB_SYSTEM/eachvec

add wave  -divider INPUTS
add wave -noupdate /TB_SYSTEM/TB_SYSTEM_CLOCK_50
add wave -noupdate /TB_SYSTEM/TB_SYSTEM_RESET_InHigh
add wave -noupdate /TB_SYSTEM/TB_SYSTEM_SS_InLow
add wave -noupdate /TB_SYSTEM/TB_SYSTEM_MOSI_In
add wave -noupdate /TB_SYSTEM/TB_SYSTEM_SCK_In
add wave -noupdate /TB_SYSTEM/TB_SYSTEM_data_In

add wave  -divider OUTPUTS
add wave -noupdate -radix Unsigned /TB_SYSTEM/TB_SYSTEM_MISO_Out
add wave -noupdate -radix Unsigned /TB_SYSTEM/TB_SYSTEM_newData_Out
add wave -noupdate -radix Binary /TB_SYSTEM/TB_SYSTEM_data_Out

add wave  -divider REGISTERS
add wave  -noupdate -radix Unsigned /TB_SYSTEM/BB_SYSTEM_u0/SPI_SLAVE_u0/State_Register

restart
run 1ms

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 0} {40000000 ps} 0}
WaveRestoreCursors {{Cursor 1} {20000000 ps} 0}
quietly wave cursor active 0
quietly wave cursor active 1
configure wave -namecolwidth 300
configure wave -valuecolwidth 50
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {40000000 ps}
