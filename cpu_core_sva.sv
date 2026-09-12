`timescale 1ns / 1ps

module cpu_core_sva(
    input clk,
    input reset,
    input mem_req,
    input we,
    input io_req,
    input cpu_ready,
    input [3:0] SC,
    input S
);

    // ---------------------------------------------------------
    // [1] Reset 동작 검증
    // reset이 active-low로 들어올 때, 제어 신호들이 즉시 0이 되는지 확인
    // ---------------------------------------------------------
    property p_reset_check;
        @(posedge clk) !reset |=> (!mem_req && !io_req && !we && SC == 4'h0);
    endproperty
    assert property(p_reset_check) 
        else $error("[SVA FAIL] Reset 시 제어 신호가 초기화되지 않았습니다.");

    // ---------------------------------------------------------
    // [2] Fetch 단계 대기(Stall) 로직 검증 (Corner Case)
    // SC == 1 (T1) 상태에서 cpu_ready가 0이면, 다음 클럭에서도 SC는 1을 유지해야 함
    // ---------------------------------------------------------
    property p_stall_fetch;
        @(posedge clk) disable iff(!reset)
        (SC == 4'h1 && !cpu_ready) |=> (SC == 4'h1);
    endproperty
    assert property(p_stall_fetch) 
        else $error("[SVA FAIL] Fetch(T1) 대기 상태에서 FSM이 비정상적으로 넘어갔습니다.");

    // ---------------------------------------------------------
    // [3] mem_req 1-Cycle Pulse 규칙 검증
    // 코드 분석 결과, T0에서 mem_req=1이 되고 T1에서 즉시 0이 됨. 
    // 즉, 2클럭 연속으로 mem_req가 High가 되면 프로토콜 위반임.
    // ---------------------------------------------------------
    property p_mem_req_pulse;
        @(posedge clk) disable iff(!reset)
        mem_req |=> !mem_req;
    endproperty
    assert property(p_mem_req_pulse) 
        else $error("[SVA FAIL] mem_req 신호가 1-Cycle Pulse 규칙을 위반했습니다.");

    // ---------------------------------------------------------
    // [4] HALT(S==0) 상태 유지 검증
    // S 플래그가 0이 되면, SC는 무조건 이전 상태 값을 유지해야 함
    // ---------------------------------------------------------
    property p_halt_check;
        @(posedge clk) disable iff(!reset)
        (S == 1'b0) |=> (SC == $past(SC));
    endproperty
    assert property(p_halt_check) 
        else $error("[SVA FAIL] HALT(S=0) 상태임에도 SC 값이 변경되었습니다.");

    // ---------------------------------------------------------
    // [5] Memory Write 규칙 검증
    // we가 1로 올라가는 시점(SC==5 등)에는 항상 mem_req가 1이어야 함
    // ---------------------------------------------------------
    property p_we_req_sync;
        @(posedge clk) disable iff(!reset)
        $rose(we) |-> (mem_req == 1'b1);
    endproperty
    assert property(p_we_req_sync) 
        else $error("[SVA FAIL] mem_req 없이 Write Enable(we)이 활성화되었습니다.");

endmodule