# Makefile for Project 2 — Memory Bandwidth & Latency Lab

NVCC ?= nvcc
ARCH ?= sm_121
SRC := bandwidth_test.cu
BIN := bandwidth_test

.PHONY: all build test run workset stride block alloc uma ncu plot verify clean

all: build

build: $(BIN)

$(BIN): $(SRC)
	$(NVCC) -arch=$(ARCH) -lineinfo -o $(BIN) $(SRC)

test: $(BIN)
	@mkdir -p results
	./$(BIN) --test

run: $(BIN)
	@mkdir -p results
	./$(BIN) --run
	python3 plot_results.py

workset: $(BIN)
	@mkdir -p results
	./$(BIN) --workset

stride: $(BIN)
	@mkdir -p results
	./$(BIN) --stride

block: $(BIN)
	@mkdir -p results
	./$(BIN) --block

alloc: $(BIN)
	@mkdir -p results
	./$(BIN) --alloc

uma: $(BIN)
	@mkdir -p results
	./$(BIN) --uma

ncu: $(BIN)
	@mkdir -p results
	-ncu --set full --target-processes all --csv --log-file results/ncu_sequential_read.csv ./$(BIN) --ncu sequential_read
	-ncu --set full --target-processes all --csv --log-file results/ncu_read_write_copy.csv ./$(BIN) --ncu read_write_copy
	-ncu --set full --target-processes all --csv --log-file results/ncu_saxpy.csv ./$(BIN) --ncu saxpy

plot: run
	python3 plot_results.py

verify: $(BIN)
	@mkdir -p results
	./$(BIN) --test
	@echo "Checking artifacts..."
	@for f in results/bandwidth_workset.csv results/bandwidth_stride.csv results/bandwidth_block.csv results/bandwidth_alloc.csv results/bandwidth_uma.csv; do \
	  if [ -f $$f ]; then echo "  $$f OK"; else echo "  $$f MISSING"; exit 1; fi; \
	done

clean:
	rm -f $(BIN) results/*.csv results/*.png results/*.txt results/*.log
