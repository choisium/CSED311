=========================================================
		CSED311 Lab7-DMA README
		 29-20160595-20160169
		     최규민, 최수민 조
=========================================================

[현재 구현 사항]

1. External Device의 Interrupt는 num_clock이 'd185 일 때 raise됩니다.
2. Device's data가 저장되는 메모리의 주소범위는 'd23 ~ 'd34로, 'h1 ~ 'hc의 data가 입력됩니다.

[Waveform 확인방법(Windows, ModelSim 기준)]

1. 아래 목록에 있는 Object들을 Wave에서 확인할 수 있도록 Add Wave 해줍니다.

--- clk 관련 ---
/cpu_TB/ : clk, num_clock, num_inst

--- Signals ---
/cpu_TB/UUT/ : bus_access	// CPU is accessing the memory
/cpu_TB/ : busRequest, busGrant
/cpu_TB/DMA/ : access_memory	// DMA controller is accessing the memory

--- Memory ---
/cpu_TB/NUUT/memory		// Memory는 [23] ~ [34] 의 값을 확인하면 됩니다.

2. 시뮬레이션 실행(run -all) 이후, num_clock 'd185 로 이동합니다.

3. num_clock 'd185 ~ 'd206에서 Signals에 있는 object들의 동작이 
   	lab7_DMA ppt 13/19 page의 동작과 동일함을 확인할 수 있습니다.

4. num_clock 'd195, 'd200, 'd206에서 Memory에 external device의 data가 4 word씩 쓰여져, 
	총 12 word data가 모두 전달됨을 확인할 수 있습니다. (Memory[23] ~ [34])

5. dma 동작중에도 num_inst가 증가하는 것으로 CPU가 계속 동작하고 있음을 확인할 수 있습니다.