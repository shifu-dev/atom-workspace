find ./ -iname *.h | xargs clang-format -i;
find ./ -iname *.cppm | xargs clang-format -i;
find ./ -iname *.cxx | xargs clang-format -i;
