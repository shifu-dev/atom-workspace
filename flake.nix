{
    description = "atom-workspace";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        atom_core = {
            url = "./atom.core";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        atom_logging = {
            url = "./atom.logging";
            inputs.atom_core.follows = "atom_core";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        atom_engine = {
            url = "./atom.engine";
            inputs.atom_core.follows = "atom_core";
            inputs.atom_logging.follows = "atom_logging";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        atom_editor = {
            url = "./atom.editor";
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

        atom_core_env = inputs.atom_core.env.${system}.default;
        atom_logging_env = inputs.atom_logging.env.${system}.default;
        atom_engine_env = inputs.atom_engine.env.${system}.default;
        atom_editor_env = inputs.atom_editor.env.${system}.default;
    in
    {
        devShells.${system}.default = stdenv.mkDerivation rec {

            name = "atom-workspace";

            propagatedBuildInputs =
                atom_core_env.propagatedBuildInputs ++
                atom_logging_env.propagatedBuildInputs ++
                atom_engine_env.propagatedBuildInputs;

            nativeBuildInputs =
                atom_core_env.nativeBuildInputs ++
                atom_logging_env.nativeBuildInputs ++
                atom_engine_env.nativeBuildInputs ++
                atom_editor_env.nativeBuildInputs;

            CXXFLAGS = lib.strings.concatMapStrings (v: " -I " + v) (
                atom_core_env.clang_scan_deps_include_paths ++
                atom_logging_env.clang_scan_deps_include_paths ++
                atom_engine_env.clang_scan_deps_include_paths ++
                atom_editor_env.clang_scan_deps_include_paths);

            CMAKE_GENERATOR = "Ninja";
            CMAKE_BUILD_TYPE = "Debug";
            CMAKE_EXPORT_COMPILE_COMMANDS = "true";
            imgui_DIR = atom_engine_env.envVars.imgui_DIR;
            stb_include_dir = atom_engine_env.envVars.stb_include_dir;
        };
    };
}
