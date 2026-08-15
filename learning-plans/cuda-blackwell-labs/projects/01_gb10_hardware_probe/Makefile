# Makefile for GB10 Hardware Probe (CUDA Blackwell Labs Project 1)
# Safe build commands only; no user-controlled shell inputs.

NVCC ?= nvcc
ARCH ?= sm_121
PTX_ARCH ?= compute_121
SRC := probe.cu
BIN := probe
PTX := probe.ptx

.PHONY: all build ptx run clean verify

all: build ptx

build: $(BIN)

$(BIN): $(SRC)
	$(NVCC) -arch=$(ARCH) -lineinfo -o $@ $<

ptx: $(PTX)

$(PTX): $(SRC)
	$(NVCC) -arch=$(PTX_ARCH) -ptx -o $@ $<

run: $(BIN)
	@mkdir -p results
	./$(BIN) results/probe_output.txt
	@echo "---- free -h ----" >> results/probe_output.txt
	@-free -h >> results/probe_output.txt 2>&1 || true
	@echo "---- nvidia-smi memory ----" >> results/probe_output.txt
	@-nvidia-smi --query-gpu=memory.total,memory.free,memory.used --format=csv >> results/probe_output.txt 2>&1 || true
	@echo "---- numactl --hardware (if available) ----" >> results/probe_output.txt
	@-numactl --hardware >> results/probe_output.txt 2>&1 || echo "numactl not available" >> results/probe_output.txt

verify: run
	@echo "Checking artifacts..."
	@test -f $(BIN) && echo "  $(BIN): OK" || (echo "  $(BIN): MISSING" && exit 1)
	@test -f $(PTX) && grep -q probe_kernel $(PTX) && echo "  $(PTX) contains probe_kernel: OK" || (echo "  $(PTX): kernel not found" && exit 1)
	@test -f results/probe_output.txt && echo "  results/probe_output.txt: OK" || (echo "  results/probe_output.txt: MISSING" && exit 1)

clean:
	rm -f $(BIN) $(PTX) results/probe_output.txt

.DEFAULT_GOAL := all
