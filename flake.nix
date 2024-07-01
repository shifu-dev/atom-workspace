{
  description = "atom-workspace";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs_glfw.url = "github:nixos/nixpkgs/7a339d87931bba829f68e94621536cad9132971a";

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
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      stdenv = pkgs.llvmPackages_18.libcxxStdenv;

      fmt_pkg = pkgs.fmt.override { stdenv = stdenv; };
      catch2_pkg = pkgs.catch2_3.override { stdenv = stdenv; };
      glslang_pkg = pkgs.glslang.override { stdenv = stdenv; };
      glfw_pkg = inputs.nixpkgs_glfw.legacyPackages.${system}.pkgs.glfw;

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

      imgui_pkg = stdenv.mkDerivation rec {
        pname = "imgui";
        version = "docking";
        src = inputs.imgui;
        dontBuild = true;

        installPhase = ''
          mkdir -p $out/include/imgui

          cp *.h $out/include/imgui
          cp *.cpp $out/include/imgui
          cp -a backends $out/include/imgui/
          cp -a misc $out/include/imgui/
        '';
      };

      msdfgen_pkg = stdenv.mkDerivation rec {
        pname = "msdfgen";
        version = "v1.12";

        src = pkgs.fetchFromGitHub {
          owner = "Chlumsky";
          repo = "msdfgen";
          rev = version;
          hash = "sha256-QLzfZP9Xsc5HBvF+riamqVY0pYN5umyEsiJV7W8JNyI=";
        };

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

      msdf-atlas-gen_pkg = stdenv.mkDerivation rec {
        pname = "msdf-atlas-gen";
        version = "v1.3";

        src = pkgs.fetchFromGitHub {
          owner = "Chlumsky";
          repo = "msdf-atlas-gen";
          rev = version;
          hash = "sha256-ji3L7urLdqAPkO1ZRYFWiAsQ8q8igKu74oTe18OtYz4=";
          fetchSubmodules = true;
          leaveDotGit = true;
        };

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
          cmake \
            -S . \
            -B . \
            -G Ninja \
            -D CMAKE_INSTALL_PREFIX=$out \
            -D MSDF_ATLAS_MSDFGEN_EXTERNAL=ON \
            -D MSDF_ATLAS_NO_ARTERY_FONT=ON \
            -D MSDF_ATLAS_USE_VCPKG=OFF \
            -D MSDF_ATLAS_USE_SKIA=OFF \
            -D MSDF_ATLAS_INSTALL=ON;
        '';
      };

      clang_scan_deps_include_paths = [
        "/nix/store/csml9b5w7z51yc7hxgd2ax4m6vj36iyq-libcxx-18.1.5-dev/include"
        "/nix/store/2sf9x4kf8lihldhnhp2b8q3ybas3p83l-compiler-rt-libc-18.1.5-dev/include"
        "/nix/store/k3701zl6gmx3la7y4dnflcvf3xfy88kh-python3-3.11.9/include"
        "/nix/store/csml9b5w7z51yc7hxgd2ax4m6vj36iyq-libcxx-18.1.5-dev/include/c++/v1"
        "/nix/store/fymdqlxx6zsqvlmfwls3h2fly9kz0vcf-clang-wrapper-18.1.5/resource-root/include"
        "/nix/store/s3pvsv4as7mc8i2nwnk2hnsyi2qdj4bq-glibc-2.39-31-dev/include"

        # "${fmt_pkg}/include"
        "/nix/store/83ky6ybp7lw8dqn3s47r2iqrby508l60-fmt-10.2.1-dev/include"
        "${catch2_pkg}/include"
        "${imgui_pkg}/include"
        "${glslang_pkg}/include"
        "${glfw_pkg}/include"
        "${cpptrace_pkg}/include"
        "${msdfgen_pkg}/include"
        "${msdf-atlas-gen_pkg}/include"

        "${pkgs.magic-enum}/include"
        "${pkgs.glm}/include"
        "${pkgs.entt}/include"
        "${pkgs.stb}/include"
        "${pkgs.box2d}/include"
      ];
    in
    {
      devShells.${system}.default = stdenv.mkDerivation rec {

        name = "atom-workspace";

        nativeBuildInputs = with pkgs; [
          fmt_pkg
          catch2_pkg
          imgui_pkg
          glslang_pkg
          glfw_pkg
          cpptrace_pkg
          msdfgen_pkg
          msdf-atlas-gen_pkg

          magic-enum
          glm
          entt
          stb
          box2d

          cmake
          cmake-format
          ninja
          git
        ];

        imgui_DIR = "${imgui_pkg}/include/imgui";
        stb_include_dir = "${pkgs.stb}/include";

        CXXFLAGS = lib.strings.concatMapStrings (v: " -I " + v) clang_scan_deps_include_paths;
        CMAKE_GENERATOR = "Ninja";
        CMAKE_BUILD_TYPE = "Debug";
        CMAKE_EXPORT_COMPILE_COMMANDS = "true";
      };
    };
}
