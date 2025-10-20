cmake_minimum_required(VERSION 3.20)

project(kspaceFirstOrderOMP LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(HDF5 REQUIRED COMPONENTS C HL)
find_package(ZLIB REQUIRED)
find_package(SZIP QUIET)
find_package(OpenMP REQUIRED COMPONENTS CXX)

find_path(KSPACE_FFTW_INCLUDE_DIR
  NAMES fftw3.h
  PATH_SUFFIXES include include/fftw3
)

find_library(KSPACE_FFTW_LIB
  NAMES fftw3f libfftw3f fftw3f-3 libfftw3f-3
  PATH_SUFFIXES lib lib64
)

find_library(KSPACE_FFTW_OMP_LIB
  NAMES fftw3f_omp libfftw3f_omp fftw3f_omp-3 libfftw3f_omp-3
  PATH_SUFFIXES lib lib64
)

if(NOT KSPACE_FFTW_INCLUDE_DIR OR NOT KSPACE_FFTW_LIB OR NOT KSPACE_FFTW_OMP_LIB)
  message(
    FATAL_ERROR
    "FFTW single-precision OpenMP libraries (fftw3f, fftw3f_omp) not found. "
    "Add their locations via CMAKE_PREFIX_PATH or FFTW-specific variables."
  )
endif()

add_executable(kspaceFirstOrder-OMP
  main.cpp
  Containers/MatrixContainer.cpp
  Containers/OutputStreamContainer.cpp
  GetoptWin64/Getopt.cpp
  Hdf5/Hdf5File.cpp
  Hdf5/Hdf5FileHeader.cpp
  KSpaceSolver/KSpaceFirstOrderSolver.cpp
  Logger/Logger.cpp
  MatrixClasses/BaseFloatMatrix.cpp
  MatrixClasses/BaseIndexMatrix.cpp
  MatrixClasses/ComplexMatrix.cpp
  MatrixClasses/FftwComplexMatrix.cpp
  MatrixClasses/FftwRealMatrix.cpp
  MatrixClasses/IndexMatrix.cpp
  MatrixClasses/RealMatrix.cpp
  OutputStreams/BaseOutputStream.cpp
  OutputStreams/CuboidOutputStream.cpp
  OutputStreams/IndexOutputStream.cpp
  OutputStreams/WholeDomainOutputStream.cpp
  Parameters/CommandLineParameters.cpp
  Parameters/Parameters.cpp
)

target_include_directories(kspaceFirstOrder-OMP
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${KSPACE_FFTW_INCLUDE_DIR}
    ${HDF5_INCLUDE_DIRS}
)

target_compile_definitions(kspaceFirstOrder-OMP PRIVATE _CONSOLE)

set(_hdf5_libs ${HDF5_LIBRARIES})
if(HDF5_HL_LIBRARIES)
  list(APPEND _hdf5_libs ${HDF5_HL_LIBRARIES})
endif()
list(REMOVE_DUPLICATES _hdf5_libs)

target_link_libraries(kspaceFirstOrder-OMP
  PRIVATE
    ${_hdf5_libs}
    ${KSPACE_FFTW_LIB}
    ${KSPACE_FFTW_OMP_LIB}
    OpenMP::OpenMP_CXX
    ZLIB::ZLIB
)

if(SZIP_FOUND)
  target_link_libraries(kspaceFirstOrder-OMP PRIVATE SZIP::SZIP)
endif()

if(MSVC)
  target_compile_options(kspaceFirstOrder-OMP PRIVATE /O2 /fp:fast /arch:AVX /MP)
  set_property(TARGET kspaceFirstOrder-OMP PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
else()
  target_compile_options(kspaceFirstOrder-OMP PRIVATE -O3)
endif()

set_target_properties(kspaceFirstOrder-OMP PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
