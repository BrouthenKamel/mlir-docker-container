# 1. Build
```bash
docker build -t mlir .
```

# 2. Run
```bash
docker run -it mlir /bin/bash
```

# 3. Sanity Check

## 3.1. MLIR Tests

### 3.1.1. MLIR Build

```bash
cmake --build /opt/mlir-build --target check-mlir
```

Result:

```bash
[0/1] Running the MLIR regression tests

Testing Time: 11.28s

Total Discovered Tests: 2892
  Unsupported      :  433 (14.97%)
  Passed           : 2458 (84.99%)
  Expectedly Failed:    1 (0.03%)
```

### 3.1.2. MLIR Python Binding

```bash
cmake --build /opt/mlir-build --target check-mlir-python
```

Result:

```bash
[0/1] Running lit suite /opt/llvm-project/mlir/test/python

Testing Time: 3.46s

Total Discovered Tests: 84
  Unsupported:  5 (5.95%)
  Passed     : 79 (94.05%)
```

## 3.1. MLIR Binaries

### 3.1.1. mlir-opt

```bash
mlir-opt --version
```

Result

```bash
LLVM (http://llvm.org/):
  LLVM version 19.1.7
  Optimized build.
```

### 3.1.2. mlir-cpu-runner

#### 3.1.2.1 Version

```bash
mlir-cpu-runner --version
```

Result

```bash
LLVM (http://llvm.org/):
  LLVM version 19.1.7
  Optimized build.
```

#### 3.1.2.1 Execution
```bash
time echo 'module {
  func.func @main() {
    %A = memref.alloc() : memref<2x2xf32>
    %B = memref.alloc() : memref<2x2xf32>
    %C = memref.alloc() : memref<2x2xf32>
    linalg.matmul ins(%A, %B : memref<2x2xf32>, memref<2x2xf32>) outs(%C : memref<2x2xf32>)
    return
  }
}' \
| mlir-opt -pass-pipeline='builtin.module(
  canonicalize,
  buffer-deallocation-pipeline,
  convert-bufferization-to-memref,
  convert-linalg-to-loops,
  scf-forall-to-parallel,
  convert-scf-to-openmp,
  expand-strided-metadata,
  finalize-memref-to-llvm,
  convert-scf-to-cf,
  lower-affine,
  convert-openmp-to-llvm,
  convert-vector-to-llvm,
  convert-math-to-llvm,
  convert-math-to-libm,
  finalize-memref-to-llvm,
  convert-func-to-llvm,
  convert-index-to-llvm,
  convert-arith-to-llvm,
  convert-cf-to-llvm,
  reconcile-unrealized-casts,
  canonicalize,
  cse
)' \
| mlir-cpu-runner -e main -entry-point-result=void \
    -shared-libs=/opt/mlir-build/lib/libmlir_runner_utils.so \
    -shared-libs=/opt/mlir-build/lib/libmlir_c_runner_utils.so
```

Result

```bash
real    0m0.027s
user    0m0.015s
sys     0m0.019s
```

## 3.2. MLIR Python Package

```bash
python -c "import mlir; print('MLIR Python bindings loaded successfully')"
```

Result

```bash
MLIR Python bindings loaded successfully
```