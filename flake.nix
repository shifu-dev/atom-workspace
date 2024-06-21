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

      glfw_pkg = inputs.nixpkgs_glfw.legacyPackages.${system}.pkgs.glfw;

      cpptrace_pkg = stdenv.mkDerivation {

        name = "cpptrace";

        src = inputs.cpptrace;

        nativeBuildInputs = with pkgs; [
          cmake
          git
        ];

        configurePhase = ''
          cmake -S . -B build \
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

      glslang_pkg = stdenv.mkDerivation rec {
        pname = "glslang";
        version = "14.2.0";

        src = pkgs.fetchFromGitHub {
          owner = "KhronosGroup";
          repo = "glslang";
          rev = version;
          hash = "sha256-B6jVCeoFjd2H6+7tIses+Kj8DgHS6E2dkVzQAIzDHEc=";
        };

        # These get set at all-packages, keep onto them for child drvs
        passthru = {
          spirv-tools = pkgs.spirv-tools;
          spirv-headers = pkgs.spirv-headers;
        };

        nativeBuildInputs = with pkgs; [
          cmake
          python3
          bison
          jq
        ];

        postPatch = ''
          cp --no-preserve=mode -r "${pkgs.spirv-tools.src}" External/spirv-tools
          ln -s "${pkgs.spirv-headers.src}" External/spirv-tools/external/spirv-headers
        '';

        # This is a dirty fix for lib/cmake/SPIRVTargets.cmake:51 which includes this directory
        postInstall = ''
          mkdir $out/include/External
        '';

        # Fix the paths in .pc, even though it's unclear if these .pc are really useful.
        postFixup = ''
          substituteInPlace $out/lib/pkgconfig/*.pc \
          --replace '=''${prefix}//' '=/'

          # add a symlink for backwards compatibility
          ln -s $out/bin/glslang $out/bin/glslangValidator
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
          cmake \
            -S . \
            -B . \
            -G Ninja \
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
          hash = "sha256-SfzQ008aoYI8tkrHXsXVQq9Qq+NIqT1zvSIHK1LTbLU=";
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
        "/nix/store/hrssqr2jypca2qcqyy1xmfdw71nv6n14-catch2-3.5.2/include"
        "/nix/store/zc8xnz48ca61zjplxc3zz1ha3zss046p-fmt-10.2.1-dev/include"
        "/nix/store/2j35qpxbprdgcixyg70lyy6m0yay9352-magic-enum-0.9.5/include"
        "/nix/store/k3701zl6gmx3la7y4dnflcvf3xfy88kh-python3-3.11.9/include"
        "/nix/store/csml9b5w7z51yc7hxgd2ax4m6vj36iyq-libcxx-18.1.5-dev/include/c++/v1"
        "/nix/store/fymdqlxx6zsqvlmfwls3h2fly9kz0vcf-clang-wrapper-18.1.5/resource-root/include"
        "/nix/store/s3pvsv4as7mc8i2nwnk2hnsyi2qdj4bq-glibc-2.39-31-dev/include"

        "${glfw_pkg}/include"
        "${pkgs.glm}/include"
        "${pkgs.entt}/include"
        "${pkgs.box2d}/include"
        "${pkgs.stb}/include"
        "${glslang_pkg}/include"
        "${msdfgen_pkg}/include"
        "${msdf-atlas-gen_pkg}/include"
      ];
    in
    {
      devShells.${system}.default = stdenv.mkDerivation rec {

        name = "atom-workspace";

        nativeBuildInputs = with pkgs; [
          fmt
          magic-enum
          cpptrace_pkg
          glfw_pkg
          imgui_pkg
          catch2_3
          glm
          entt
          stb
          box2d
          glslang_pkg
          msdfgen_pkg
          msdf-atlas-gen_pkg

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
