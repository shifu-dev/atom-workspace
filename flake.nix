{
  description = "atom-workspace";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    atom_core = {
      url = "git+file:atom.core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atom_logging = {
      url = "git+file:atom.logging";
      inputs.atom_core.follows = "atom_core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atom_engine = {
      url = "git+file:atom.engine";
      inputs.atom_core.follows = "atom_core";
      inputs.atom_logging.follows = "atom_logging";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atom_editor = {
      url = "git+file:atom.editor";
      inputs.atom_core.follows = "atom_core";
      inputs.atom_logging.follows = "atom_logging";
      inputs.atom_engine.follows = "atom_engine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      stdenv = pkgs.llvmPackages_18.libcxxStdenv;

      atom_core_pkg = inputs.atom_core.packages.${system}.default;
      atom_logging_pkg = inputs.atom_logging.packages.${system}.default;
      atom_engine_pkg = inputs.atom_engine.packages.${system}.default;
      atom_editor_pkg = inputs.atom_editor.packages.${system}.default;

      clang_scan_deps_include_paths =
        inputs.atom_core.clang_scan_deps_include_paths +
        inputs.atom_logging.clang_scan_deps_include_paths +
        inputs.atom_engine.clang_scan_deps_include_paths +
        inputs.atom_editor.clang_scan_deps_include_paths;
    in
    {
      devShells.${system}.default = stdenv.mkDerivation {

        name = "atom-workspace";

        propagatedNativeBuildInputs =
          atom_core_pkg.propagatedNativeBuildInputs ++
          atom_logging_pkg.propagatedNativeBuildInputs ++
          atom_engine_pkg.propagatedNativeBuildInputs ++
          atom_editor_pkg.propagatedNativeBuildInputs;

        propagatedBuildInputs =
          atom_core_pkg.propagatedBuildInputs ++
          atom_logging_pkg.propagatedBuildInputs ++
          atom_engine_pkg.propagatedBuildInputs ++
          atom_editor_pkg.propagatedBuildInputs;

        nativeBuildInputs =
          atom_core_pkg.nativeBuildInputs ++
          atom_logging_pkg.nativeBuildInputs ++
          atom_engine_pkg.nativeBuildInputs ++
          atom_editor_pkg.nativeBuildInputs;

        buildInputs =
          atom_core_pkg.buildInputs ++
          atom_logging_pkg.buildInputs ++
          atom_engine_pkg.buildInputs ++
          atom_editor_pkg.buildInputs;

        imgui_DIR = atom_engine_pkg.imgui_DIR;
        stb_include_dir = atom_engine_pkg.stb_include_dir;

        CXXFLAGS = clang_scan_deps_include_paths;
        CMAKE_GENERATOR = "Ninja";
        CMAKE_BUILD_TYPE = "Debug";
        CMAKE_EXPORT_COMPILE_COMMANDS = "true";
      };
    };
}
