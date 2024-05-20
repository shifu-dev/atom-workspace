cmake_minimum_required(VERSION 3.28)
project(atom-workspace VERSION 0.1.0)

add_subdirectory(atom.core)
set(atom_core_DIR "./atom.core")

add_subdirectory(atom.logging)
set(atom_logging_DIR "./atom.logging")

add_subdirectory(atom.engine)
set(atom_engine_DIR "./atom.engine")

add_subdirectory(atom.editor)
set(atom_editor_DIR "./atom.editor")
