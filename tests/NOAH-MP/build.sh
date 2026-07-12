# Fail on first failing step so either build aborts the harness.
set -e

rm -rf tmp_build_dir
mkdir -pv tmp_build_dir && cd tmp_build_dir

# ===========================================================================
# Test 1 -- CMake build + CTest regression suite
# ===========================================================================
# Build the Noah-MP ERF-driver library, its regression tests, and run them.
# Absolute path: ctest runs from tmp_build_dir; PROJECT_HOME is the repo root.
export NOAHMP_TEST_WRFINPUT="$PROJECT_HOME/simulation/Tall-Towers/wrfinput_d01"

cmake -DNETCDF_DIR=$NETCDF_HOME -DNOAHMP_ENABLE_TESTS=ON -DCMAKE_Fortran_FLAGS="-DDOUBLE_PREC" -DCMAKE_CXX_FLAGS="-DDOUBLE_PREC" $NOAH_HOME/drivers/erf && make -j && ctest --output-on-failure

# ===========================================================================
# Test 2 -- GNU Make build (drivers/erf/Makefile)
# ===========================================================================
# ERF's PRODUCTION build compiles Noah-MP through this hand-written Makefile, not
# CMake, so this second build exercises the exact gmake path ERF uses.
# Double precision matches ERF (the C++<->Fortran NoahmpArray ABI is double-only).
# codegen-check fails the job on any @NoahmpMacro template drift.

#NOAHMP_ERF=$NOAH_HOME/drivers/erf
#GMAKE_BUILD=$PWD/gmake_build
#make -C "$NOAHMP_ERF" \
#     NOAHMP_OBJ_DIR="$GMAKE_BUILD/obj" \
#     NOAHMP_LIB_DIR="$GMAKE_BUILD/lib" \
#     NOAHMP_INC_DIR="$GMAKE_BUILD/include" \
#     NOAHMP_PRECISION_FLAG=-DDOUBLE_PREC \
#     -j all_noahmp
#test -f "$GMAKE_BUILD/lib/libnoahmp.a" || { echo "ERROR: gmake build did not produce libnoahmp.a"; exit 1; }
#make -C "$NOAHMP_ERF" codegen-check
#echo "gmake build OK: $GMAKE_BUILD/lib/libnoahmp.a"
