
VERILOG_SRC=$(wildcard ../rtl/*.*v)  
TESTBENCH_SRC=$(wildcard ../testbench/*.*v)

build-dw:
	/bin/bash -c "vlog ${DW_SRC} "	

build:
	/bin/bash -c "vlog -sv +incdir+../testbench $(TESTBENCH_SRC) $(VERILOG_SRC)"	

eval: build
	mkdir -p logs logs/test 
	/bin/bash -c "vsim -c -voptargs=+acc tb_top +input_dir=../inputs -do \"run -all\" | tee logs/output.log "
	grep -r "INFO" logs/output.log > logs/INFO.log
	grep -r "INFO" logs/output.log | grep  Result > logs/RESULTS.log

debug: build
	/bin/bash -c "vsim -voptargs=+acc tb_top +input_dir=../inputs/ " 


clean:
	rm -rf work logs results transcript
