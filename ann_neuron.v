module sigmoid (
    input signed [15:0] x,
    output reg [15:0] y
);
    // Declare all variables at module level
    reg [15:0] lut [0:255];
    integer i;
    reg [7:0] index;  // Moved outside always block
    
    // File loading status
    reg load_error = 0;
    
    // Initialize LUT - Proper system task usage
    initial begin
        // First attempt to load file
        $readmemh("sigmoid_lut.mem", lut);
        
        // Verify load by checking first entry
        if (lut[0] === 16'hxxxx) begin
            $display("WARNING: sigmoid_lut.mem not loaded properly - using defaults");
            load_error = 1;
            
            // Create approximate sigmoid curve
            for (i = 0; i < 256; i = i + 1) begin
                lut[i] = (i < 32)  ? 16'h0000 :
                         (i < 224) ? (i << 8) :
                                     16'hFFFF;
            end
        end
    end

    // Continuous assignment with proper declarations
    always @(*) begin
        // Input scaling and saturation
        index = (x >>> 8) + 128;
        if (index > 255) index = 255;
        else if (index < 0) index = 0;
        
        // Output selection
        y = load_error ? 16'h7FFF : lut[index];
        
        // Debug output
        $display("Sigmoid: in=%6d (0x%04h) -> idx=%3d -> out=0x%04h %s",
                x, x, index, y, 
                load_error ? "(DEFAULT)" : "");
    end
endmodule
module ann_neuron (
    input clk,
    output reg [15:0] result
);
    reg [7:0] image [0:783];
    reg signed [7:0] weights [0:783];
    reg signed [15:0] bias_mem [0:0];
    reg signed [15:0] bias;

    integer i;
    reg signed [31:0] acc;
    wire [15:0] activated;

    initial begin
        $readmemh("mnist_image.mem", image);
        $readmemh("weights_0.mem", weights);
        $readmemh("bias_0.mem", bias_mem);       
        bias = bias_mem[0];
    end

    // Pipeline stage 1: Multiply-accumulate
    always @(posedge clk) begin
        acc = bias;
        for (i = 0; i < 784; i = i + 1)
            acc = acc + image[i] * weights[i];
    end

    // Pipeline stage 2: Activation
    sigmoid act (
        .x(acc[23:8]),  // Scale down from 32-bit to 16-bit signed
        .y(activated)
    );

    always @(posedge clk) begin
        result <= activated;
    end
endmodule

