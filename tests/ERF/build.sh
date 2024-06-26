rm -rf tmp_build_dir
mkdir -pv tmp_build_dir && cd tmp_build_dir
cmake -DCMAKE_INSTALL_PREFIX:PATH=./install \
   -DCMAKE_CXX_COMPILER:STRING=mpicxx \
   -DCMAKE_C_COMPILER:STRING=mpicc \
   -DCMAKE_Fortran_COMPILER:STRING=mpifort \
   -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo \
   -DERF_DIM:STRING=3 \
   -DERF_ENABLE_MPI:BOOL=ON \
   -DERF_ENABLE_TESTS:BOOL=ON \
   -DERF_ENABLE_FCOMPARE:BOOL=ON \
   -DERF_ENABLE_DOCUMENTATION:BOOL=OFF \
   -DERF_ENABLE_NETCDF:BOOL=ON \
   -DNETCDF_DIR=$NETCDF_ROOT \
   -DERF_ENABLE_NOAH:BOOL=ON \
   -DERF_ENABLE_HDF5:BOOL=ON \
   -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON \
   $ERF_HOME && make -j