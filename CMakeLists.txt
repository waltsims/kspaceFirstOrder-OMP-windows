cmake_minimum_required(VERSION 3.20)
project(kspaceFirstOrder-OMP LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(OpenMP REQUIRED)

find_path(FFTW3_INCLUDE_DIR NAMES fftw3.h)
find_library(FFTW3F_LIBRARY NAMES fftw3f)
find_library(FFTW3F_OMP_LIBRARY NAMES fftw3f_omp)
if(NOT FFTW3_INCLUDE_DIR OR NOT FFTW3F_LIBRARY OR NOT FFTW3F_OMP_LIBRARY)
  message(FATAL_ERROR "FFTW3 single-precision libraries with OpenMP support not found. Install libfftw3-dev.")
endif()

find_path(HDF5_INCLUDE_DIR NAMES hdf5.h PATH_SUFFIXES hdf5/serial)
find_library(HDF5_LIBRARY NAMES hdf5 hdf5_serial)
find_library(HDF5_HL_LIBRARY NAMES hdf5_hl hdf5_serial_hl)
if(NOT HDF5_INCLUDE_DIR OR NOT HDF5_LIBRARY OR NOT HDF5_HL_LIBRARY)
  message(FATAL_ERROR "HDF5 libraries not found. Install libhdf5-dev.")
endif()

find_package(ZLIB REQUIRED)
find_library(SZ_LIBRARY NAMES sz szip aec)
find_library(DL_LIBRARY NAMES dl)

set(KSPACE_SOURCES
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

add_executable(kspaceFirstOrder-OMP ${KSPACE_SOURCES})

target_include_directories(kspaceFirstOrder-OMP
  PRIVATE
    ${PROJECT_SOURCE_DIR}
    ${FFTW3_INCLUDE_DIR}
    ${HDF5_INCLUDE_DIR}
)

find_package(Git QUIET)
if(Git_FOUND)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    OUTPUT_VARIABLE KWAVE_GIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
endif()

if(NOT KWAVE_GIT_HASH)
  set(KWAVE_GIT_HASH "unknown")
endif()

target_compile_definitions(kspaceFirstOrder-OMP PRIVATE __KWAVE_GIT_HASH__="${KWAVE_GIT_HASH}")

target_link_libraries(kspaceFirstOrder-OMP
  PRIVATE
    OpenMP::OpenMP_CXX
    ${FFTW3F_LIBRARY}
    ${FFTW3F_OMP_LIBRARY}
    ${HDF5_HL_LIBRARY}
    ${HDF5_LIBRARY}
    ZLIB::ZLIB
)

if(SZ_LIBRARY)
  target_link_libraries(kspaceFirstOrder-OMP PRIVATE ${SZ_LIBRARY})
endif()

if(DL_LIBRARY)
  target_link_libraries(kspaceFirstOrder-OMP PRIVATE ${DL_LIBRARY})
endif()
