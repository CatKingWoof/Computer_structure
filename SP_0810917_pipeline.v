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
reg [11:0] reg1,reg2;
reg[4:0] WB_r,WB_r2;
reg signed[31:0] ALU1,ALU2,ALU_out,ALU_out1;
//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------
always@(*)begin
	if(reg1[11:6]==6'd0)begin
		
		// R-type
		if(reg1[5:0]==6'd0)begin

			// and
			ALU_out=ALU1&ALU2;
			
		end
		else if(reg1[5:0]==6'd1)begin

			// or
			ALU_out=ALU1|ALU2;
			
		end
		else if(reg1[5:0]==6'd2)begin

			// add
			ALU_out=ALU1+ALU2;
			
		end
		else if(reg1[5:0]==6'd3)begin

			// sub
			ALU_out=ALU1-ALU2;
			
		end
		else if(reg1[5:0]==6'd4)begin

			// slt
			if(ALU1<ALU2)begin

				ALU_out=32'd1;
				
			end
			else begin

				ALU_out=32'd0;
				
			end
			
		end
		else begin

			// sll
			ALU_out=ALU1<<ALU2;
			
		end
		

	end
	else begin

		// I-type
		if(reg1[11:6]==6'd1)begin
			
			// andi
			ALU_out=ALU1&ALU2;

		end
		else if(reg1[11:6]==6'd2)begin

			// ori
			ALU_out=ALU1|ALU2;
			
		end
		else if(reg1[11:6]==6'd3)begin

			// addi
			ALU_out=ALU1+ALU2;
			
		end
		else if(reg1[11:6]==6'd4)begin

			// subi
			ALU_out=ALU1-ALU2;
			
		end
		/*else if(reg1[11:6]==6'd5)begin

			// lw
			
			mem_addr=ALU1+ALU2;
			mem_wen=1;
			
		end
		else if(reg1[11:6]==6'd6)begin

			// sw
			mem_addr=ALU1+ALU2;
			mem_wen=0;
			
			
		end*/
	end
	
	
	end
	
	
	



always @(posedge clk,negedge rst_n) begin
	if(!rst_n)
		begin
			out_valid<='d0;
			inst_addr<='d0;
			mem_wen<='d1;
			mem_addr<='b000000000000;
			mem_din<='d0;
			count<='d0;
			for(i=0;i<32;i=i+1)begin
				r[i]<='d0;
			end
			
		end
	else begin
		//stage0
		
		if(in_valid == 1)begin
			opcode<=inst[31:26];
			rs<=inst[25:21];
			rt<=inst[20:16];
			rd<=inst[15:11];
			shamt<=inst[10:6];
			func<=inst[5:0];
			if(count<3)begin
				count<=count+1;
			end
			
			if(inst[15]==1'b1&&inst[31:26]!=1&&inst[31:26]!=2)begin
				immediate<={16'hffff,inst[15:0]};
			end	
			else begin
				immediate<= inst[15:0];
			end
			
		end
		if(count==3)begin
			out_valid<=1;
		end
		if(out_valid==1&&in_valid==0)begin
			count<=count-1;
			if(count==0)begin
				out_valid<=0;
			end
		end
		
		if(in_valid||out_valid)begin
			//stage1
			if(opcode==0)begin
				if(func=='d5)begin
					ALU1<=r[rs];
					ALU2<=shamt;
				end
				else begin
					ALU1<=r[rs];
					ALU2<=r[rt];
				end
			end
			else if(opcode!=0)begin
				ALU1<=r[rs];
				ALU2<=immediate;
			end
			
			//pc
			if((inst[31:26]==6'd7&&r[inst[25:21]]==r[inst[20:16]])||(inst[31:26]==6'd8&&r[inst[25:21]]!=r[inst[20:16]]))begin
				if(inst[15]==1'b0)begin
					inst_addr<=inst_addr+4+(inst[15:0]<<2);
				end
				else begin
					inst_addr<=inst_addr+4+({16'hffff,inst[15:0]}<<2);
				end
			end
			else begin
				inst_addr<=inst_addr+4;
			end 
			
			//forward
			reg1<={opcode[5:0],func[5:0]};
			
			if(opcode=='d0)begin
				WB_r<=rd;
			end
			else if(opcode!='d0)begin
				WB_r<=rt;
			end
			
			
			if(opcode=='d5)begin
				mem_addr<=r[rs]+immediate;
				mem_wen<=1;
			end
			
			else if(opcode=='d6)begin
				mem_addr<=r[rs]+immediate;
				mem_wen<=0;
				mem_din<=r[rt];
			end

			
			//stage2
			if(reg1[11:6]!='d7&&reg1[11:6]!='d8&&reg1[11:6]!='d5&&reg1[11:6]!='d6)begin
				ALU_out1<=ALU_out;
			end
			
			
			reg2<=reg1;
			WB_r2<=WB_r;
			//stage3
			if(reg2[11:6]!='d7&&reg2[11:6]!='d8&&reg2[11:6]!='d5&&reg2[11:6]!='d6)begin
				r[WB_r2]<=ALU_out1;
			end
			if(reg2[11:6]=='d5)begin
					r[WB_r2]<=mem_dout;
			end
			/*else if(reg2[11:6]=='d6)begin
				mem_din<=r[WB_r2];
			end*/
		end
				

		
		
	end
end
endmodule