{
  description = "atom_workspace";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs_glfw = {
      url = "github:nixos/nixpkgs/7a339d87931bba829f68e94621536cad9132971a";
    };

    fmt = {
        url = "github:fmtlib/fmt";
        flake = false;
    };

    cpptrace = {
      url = "github:jeremy-rifkin/cpptrace/v0.5.4";
      flake = false;
    };

    libdwarf-lite = {
      url = "github:jeremy-rifkin/libdwarf-lite/v0.9.2";
      flake = false;
    };

    zstd = {
      url = "github:facebook/zstd/v1.5.5";
      flake = false;
    };

    imgui = {
      url = "github:ocornut/imgui/docking";
      flake = false;
    };

    msdfgen = {
      url = "github:Chlumsky/msdfgen";
      flake = false;
    };

    msdf_atlas_gen = {
      url = "github:Chlumsky/msdf-atlas-gen";
      flake = false;
    };
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      stdenv = pkgs.llvmPackages_18.libcxxStdenv;

      catch2_pkg = pkgs.catch2_3.override { stdenv = stdenv; };
      glslang_pkg = pkgs.glslang.override { stdenv = stdenv; };
      glfw_pkg = inputs.nixpkgs_glfw.legacyPackages.${system}.pkgs.glfw;

      fmt_pkg = stdenv.mkDerivation {
          name = "fmt";
          src = inputs.fmt;

          nativeBuildInputs = with pkgs; [
              cmake
              ninja
          ];

          configurePhase = ''
              cmake -S . -B . -G Ninja \
                  -D FMT_DOC=OFF \
                  -D FMT_TEST=OFF \
                  -D CMAKE_INSTALL_PREFIX=$out;
          '';
      };

      cpptrace_pkg = stdenv.mkDerivation {
        name = "cpptrace";
        src = inputs.cpptrace;

        nativeBuildInputs = with pkgs; [
          cmake
          git
          ninja
        ];

        configurePhase = ''
          cmake -S . -B build -G Ninja \
            -D CMAKE_INSTALL_PREFIX=$out \
            -D FETCHCONTENT_FULLY_DISCONNECTED:BOOL="ON" \
            -D FETCHCONTENT_SOURCE_DIR_LIBDWARF:PATH="${inputs.libdwarf-lite}" \
            -D FETCHCONTENT_SOURCE_DIR_ZSTD:PATH="${inputs.zstd}";
        '';

        buildPhase = ''
          cmake --build build;
        '';

        installPhase = ''
          cmake --install build --prefix $out;
        '';
      };

      imgui_pkg = (pkgs.imgui.override {
        glfw = glfw_pkg;
        IMGUI_BUILD_GLFW_BINDING = true;
        IMGUI_BUILD_OPENGL3_BINDING = true;
      }).overrideAttrs (old: {
        src = inputs.imgui;
      });

      msdfgen_pkg = stdenv.mkDerivation rec {
        name = "msdfgen";
        src = inputs.msdfgen;

        nativeBuildInputs = with pkgs; [
          cmake
          ninja
        ];

        propagatedBuildInputs = with pkgs; [
          freetype
          tinyxml-2
          libpng
        ];

        configurePhase = ''
          cmake -S . -B . -G Ninja \
            -D CMAKE_INSTALL_PREFIX=$out \
            -D MSDFGEN_USE_VCPKG=OFF \
            -D MSDFGEN_USE_SKIA=OFF \
            -D MSDFGEN_INSTALL=ON;
        '';
      };

      msdf_atlas_gen_pkg = stdenv.mkDerivation rec {
        name = "msdf-atlas-gen";
        src = inputs.msdf_atlas_gen;

        nativeBuildInputs = with pkgs; [
          cmake
          ninja
        ];

        propagatedBuildInputs = with pkgs; [
          msdfgen_pkg
          freetype
          tinyxml-2
          libpng
        ];

        configurePhase = ''
          cmake -S . -B . -G Ninja \
            -D CMAKE_INSTALL_PREFIX=$out \
            -D MSDF_ATLAS_MSDFGEN_EXTERNAL=ON \
            -D MSDF_ATLAS_NO_ARTERY_FONT=ON \
            -D MSDF_ATLAS_USE_VCPKG=OFF \
            -D MSDF_ATLAS_USE_SKIA=OFF \
            -D MSDF_ATLAS_INSTALL=ON;
        '';
      };

      clang_scan_deps_include_paths = [
        "/nix/store/2ykf9vnwl6s3nvisgd9vpzm74wxabysd-clang-18.1.7-lib/lib/clang/18/include"
        "/nix/store/fsb7lmhyy01flrnviwjfz3fgm53w990v-libcxx-18.1.7-dev/include/c++/v1"
        "/nix/store/fsb7lmhyy01flrnviwjfz3fgm53w990v-libcxx-18.1.7-dev/include"
        "/nix/store/il0vjm4nf1yv4swn0pi5rimh64hf3jrz-compiler-rt-libc-18.1.7-dev/include"
        "/nix/store/ip5wiylb41wli3yy33sqibqcj6l1yawl-clang-wrapper-18.1.7/resource-root/include"
        "/nix/store/4vgk1rlzdqjnpjicb5qcxjcd4spi7wyw-glibc-2.39-52-dev/include"

        "${fmt_pkg}/include"
        "${catch2_pkg}/include"
        "${imgui_pkg}/include"
        "${glslang_pkg}/include"
        "${glfw_pkg}/include"
        "${cpptrace_pkg}/include"
        "${msdfgen_pkg}/include"
        "${msdf_atlas_gen_pkg}/include"

        "${pkgs.magic-enum}/include"
        "${pkgs.glm}/include"
        "${pkgs.entt}/include"
        "${pkgs.stb}/include"
        "${pkgs.box2d}/include"
      ];
    in
    {
      devShells.${system}.default = stdenv.mkDerivation rec {
        name = "atom_workspace";

        nativeBuildInputs = with pkgs; [
          fmt_pkg
          catch2_pkg
          imgui_pkg
          glslang_pkg
          glfw_pkg
          cpptrace_pkg
          msdfgen_pkg
          msdf_atlas_gen_pkg

          magic-enum
          glm
          entt
          stb
          box2d

          cmake
          cmake-format
          ninja
          doxygen
          graphviz
          git
        ];

        CXXFLAGS = lib.strings.concatMapStrings (v: " -I " + v) clang_scan_deps_include_paths;
        CMAKE_GENERATOR = "Ninja";
        CMAKE_BUILD_TYPE = "Debug";
        CMAKE_EXPORT_COMPILE_COMMANDS = "true";
        ATOM_DOC_DOXYFILE_DIR = ./atom_doc;

        stb_include_dir = "${pkgs.stb}/include";
      };
    };
}
