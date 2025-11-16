# Use Miniconda base image
FROM continuumio/miniconda3

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y git

# Install required Conda packages
RUN conda install -y \
    python=3.11 \
    cmake \
    ninja \
    binutils \
    c-compiler \
    cxx-compiler \
    clang \
    clangxx \
    lld \
    numpy \
    PyYAML \
    pybind11 \
    -c conda-forge

# Set working directory
WORKDIR /opt

# Clone LLVM project
RUN git clone --branch release/19.x --depth 1 https://github.com/llvm/llvm-project.git

# Create a separate build folder
RUN mkdir /opt/mlir-build

# Build MLIR + Clang + OpenMP with Python bindings
RUN cmake -S llvm-project/llvm -B /opt/mlir-build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="mlir;clang;openmp" \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DLLVM_ENABLE_LLD=ON \
    -DMLIR_ENABLE_BINDINGS_PYTHON=ON \
    -DPython3_EXECUTABLE=$(which python) \
    -Dpybind11_DIR=$(python -m pybind11 --cmakedir)

# Build
RUN cmake --build /opt/mlir-build --target check-mlir
RUN cmake --build /opt/mlir-build --target check-mlir-python

# Add built binaries to PATH
ENV PATH="/opt/mlir-build/bin:${PATH}"
ENV PYTHONPATH="/opt/mlir-build/tools/mlir/python_packages/mlir_core"

# Default command
CMD ["/bin/bash"]