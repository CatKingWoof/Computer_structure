module SP(
	// INPUT SIGNAL
	clk,
	rst_n,
	in_valid,
	inst,
	mem_dout,
	// OUTPUT SIGNAL
	out_valid,
	inst_addr,
	mem_wen,
	mem_addr,
	mem_din
);



//------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//------------------------------------------------------------------------

input                    clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg               out_valid;
output reg        [31:0] inst_addr;
output reg               mem_wen;
output reg        [11:0] mem_addr;
output reg signed [31:0] mem_din;

//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------

// REGISTER FILE, DO NOT EDIT THE NAME.
reg	signed        [31:0] r      [0:31]; 

reg [31:0] inst_out;
reg [5:0] count;
reg [5:0] opcode,func;
reg [4:0] rs,rt,rd,shamt;
reg signed[15:0] immediate;
integer i;
//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------
always @(*)begin
	if(in_valid) begin
		opcode=inst[31:26];
		rs=inst[25:21];
		rt=inst[20:16];
		rd=inst[15:11];
		shamt=inst[10:6];
		func=inst[5:0];
		immediate=inst[15:0];
	
		if(immediate[15]==1'b1&&opcode!=1&&opcode!=2)begin

			immediate={16'hffff,immediate[15:0]};

		end
	end
end	

always @(posedge clk,negedge rst_n)begin
	if(count==0)begin	
		if(opcode==6'd0)begin
			
			// R-type
			if(func==6'd0)begin

				// and
				r[rd]<=r[rs]&r[rt];
				
			end
			else if(func==6'd1)begin

				// or
				r[rd]<=r[rs]|r[rt];
				
			end
			else if(func==6'd2)begin

				// add
				r[rd]<=r[rs]+r[rt];
				
			end
			else if(func==6'd3)begin

				// sub
				r[rd]<=r[rs]-r[rt];
				
			end
			else if(func==6'd4)begin

				// slt
				if(r[rs]<r[rt])begin

					r[rd]<=32'd1;
					
				end
				else begin

					r[rd]<=32'd0;
					
				end
				
			end
			else begin

				// sll
				r[rd]<=r[rs]<<shamt;
				
			end
			

		end
		else begin

			// I-type
			if(opcode==6'd1)begin
				
				// andi
				r[rt]<=r[rs]&immediate;

			end
			else if(opcode==6'd2)begin

				// ori
				r[rt]<=r[rs]|immediate;
				
			end
			else if(opcode==6'd3)begin

				// addi
				r[rt]<=r[rs]+immediate;
				
			end
			else if(opcode==6'd4)begin

				// subi
				r[rt]<=r[rs]-immediate;
				
			end
			else if(opcode==6'd5)begin

				// lw
				
				mem_addr<=r[rs]+immediate;
				mem_wen<=1;
				
			end
			else if(opcode==6'd6)begin

				// sw
				mem_addr<=r[rs]+immediate;
				mem_wen<=0;
				mem_din<=r[rt];
				
				
			end
		end
	
	
	end
	else if(count==2)begin
		if(opcode==6'd5)begin
			r[rt]<=mem_dout;
		end

	end
end

always @(posedge clk,negedge rst_n) begin
	if(!rst_n)
		begin
			out_valid<='d0;
			inst_addr<='d0;
			mem_wen<='d0;
			mem_addr<='b000000000010;
			mem_din<='d0;
			count<='d0;
			for(i=0;i<32;i=i+1)begin
				r[i]<='d0;
			end
			
		end
	else begin
		if(in_valid == 1 )begin
			count<=1;
		end
		else if(count==1) begin
			if(opcode==6'd5||opcode==6'd6)
			begin
				count<=2;
			end
			else begin
				out_valid<=1;
				count<=3;
				if((opcode==6'd7&&r[rs]==r[rt])||(opcode==6'd8&&r[rs]!=r[rt]))begin
					inst_addr<=inst_addr+4+(immediate<<2);
				end
				else begin
					inst_addr<=inst_addr+4;
				end
			end
		end
		if(count == 2) begin
			out_valid <= 'd1;
			count<=3;
			inst_addr<=inst_addr+4;
		end
		if(out_valid) begin
			out_valid<=0;
			count<=0;
		end
		
	end
end
endmodule