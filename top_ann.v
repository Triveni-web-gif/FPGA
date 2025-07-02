module top_ann (
    input clk,
    output reg [3:0] predicted_digit
);
    wire [15:0] results [0:9];  // Changed to match neuron output width
    integer i;
    reg [15:0] max_val;
    
    // Instantiate 10 neurons
    genvar n;
    generate
        for (n = 0; n < 10; n = n + 1) begin : neurons
            ann_neuron neuron (
                .clk(clk),
                .result(results[n])
            );
        end
    endgenerate

    // Logic to select predicted digit
    always @(posedge clk) begin
        max_val = results[0];
        predicted_digit = 0;
        for (i = 1; i < 10; i = i + 1) begin
            if (results[i] > max_val) begin
                max_val = results[i];
                predicted_digit = i;
            end
        end
    end
endmodule
