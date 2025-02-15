
`timescale 1 ns / 1 ps

	module saxis_v1_0_S00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer 	C_S_AXIS_TDATA_WIDTH	= 32
    ,   parameter			PIXELS_HORIZONTAL 		= 1280
    ,   parameter			PIXELS_VERTICAL			= 1024
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID
	);
	// function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.
	function integer clogb2 (input integer bit_depth);
	  begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      bit_depth = bit_depth >> 1;
	  end
	endfunction

	// Total number of input data.
	localparam NUMBER_OF_INPUT_WORDS  = PIXELS_HORIZONTAL*PIXELS_VERTICAL*10;
	// bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);
	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	parameter [3:0] IDLE = 4'd0,        // This is the initial/idle state 

	                WRITE_FIFO  = 4'd1, // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 
					READ_DATA = 4'd3,

					STORAGE_DATA = 4'd4;
	reg  	axis_tready;
	// State variable
	reg [3:0] 	mst_exec_state;  
	// FIFO implementation signals
	genvar byte_index;     
	// FIFO write enable
	reg 		fifo_wren;
	reg [31:0]	fifo_data;
	// FIFO full flag
	reg fifo_full_flag;
	// FIFO write pointer
	reg [bit_num-1:0] write_pointer;
	// sink has accepted all the streaming data and stored in FIFO
	reg writes_done;
	// I/O Connections assignments

	assign S_AXIS_TREADY	= axis_tready;
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) 
	begin  
	  if (!S_AXIS_ARESETN) 
	  // Synchronous reset (active low)
	    begin
	      mst_exec_state <= IDLE;
		axis_tready	<= 1'b0;
	    end  
	  else
	    case (mst_exec_state)
	      IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID) begin
	              mst_exec_state <= READ_DATA;
				  axis_tready	<= 1'b1;
	            end
	          else
	            begin
	              mst_exec_state <= IDLE;
	            end
	    //   WRITE_FIFO: 
	    //     // When the sink has accepted all the streaming input data,
	    //     // the interface swiches functionality to a streaming master
	    //     if (writes_done)
	    //       begin
	    //         mst_exec_state <= IDLE;
	    //       end
	    //     else
	    //       begin
	    //         // The sink accepts and stores tdata 
	    //         // into FIFO
	    //         mst_exec_state <= WRITE_FIFO;
	    //       end
			READ_DATA: begin
				if(S_AXIS_TVALID & axis_tready) begin
				  	axis_tready	<= 1'b0;
					fifo_data	<= S_AXIS_TDATA;
					fifo_wren = 1'b1;
					mst_exec_state <= STORAGE_DATA;
				end
				else begin
	            	mst_exec_state <= IDLE;
				end
			end
			STORAGE_DATA: begin
	            mst_exec_state <= IDLE;
			end
			default: begin
	            mst_exec_state <= IDLE;
			end
	    endcase
	end

	// // // AXI Streaming Sink 
	// // // 
	// // // The example design sink is always ready to accept the S_AXIS_TDATA  until
	// // // the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	// // assign axis_tready = ((mst_exec_state == WRITE_FIFO) && (write_pointer <= NUMBER_OF_INPUT_WORDS-1));

	// always@(posedge S_AXIS_ACLK)
	// begin
	//   if(!S_AXIS_ARESETN)
	//     begin
	//       write_pointer <= 0;
	//       writes_done <= 1'b0;
	//     end  
	//   else
	//     if (write_pointer <= NUMBER_OF_INPUT_WORDS-1)
	//       begin
	//         if (fifo_wren)
	//           begin
	//             // write pointer is incremented after every write to the FIFO
	//             // when FIFO write signal is enabled.
	//             write_pointer <= write_pointer + 1;
	//             writes_done <= 1'b0;
	//           end
	//           if ((write_pointer == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
	//             begin
	//               // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	//               // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	//               writes_done <= 1'b1;
	//             end
	//       end  
	// end

	// // FIFO write enable generation
	// assign fifo_wren = S_AXIS_TVALID && axis_tready;

	// // FIFO Implementation
	// generate 
	//   for(byte_index=0; byte_index<= (C_S_AXIS_TDATA_WIDTH/8-1); byte_index=byte_index+1)
	//   begin:FIFO_GEN

	//     reg  [(C_S_AXIS_TDATA_WIDTH/4)-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];

	//     // Streaming input data is stored in FIFO

	//     always @( posedge S_AXIS_ACLK )
	//     begin
	//       if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
	//         begin
	//           stream_data_fifo[write_pointer] <= S_AXIS_TDATA[(byte_index*8+7) -: 8];
	//         end  
	//     end  
	//   end		
	// endgenerate

	// // Add user logic here

	// // User logic ends

	endmodule
