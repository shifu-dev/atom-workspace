cmake_minimum_required(VERSION 3.28)
project(atom-workspace VERSION 0.1.0)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/")

add_subdirectory("atom.core")
add_subdirectory("atom.logging")
add_subdirectory("atom.engine")
add_subdirectory("atom.editor")
add_subdirectory("samples/super-mario")
