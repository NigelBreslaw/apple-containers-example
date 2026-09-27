module example (
    input  wire clock,
    output reg  led = 1'b0
);
    always @(posedge clock)
        led <= ~led;
endmodule
