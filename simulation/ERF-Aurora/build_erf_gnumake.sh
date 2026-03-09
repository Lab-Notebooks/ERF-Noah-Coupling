# cache the value of current working directory
NodeDir=$(realpath .)

rm -rf tmp_build_dir
mkdir -pv tmp_build_dir

export CRAYPE_LINK_TYPE="dynamic"

cd "$NodeDir"
make -f GNUmakefile clean
make -f GNUmakefile
