{
  description = "OpenSSL bindings for Lean";

  inputs = {
    lean = {
      url = github:leanprover/lean4;
    };
    nixpkgs.url = github:nixos/nixpkgs/nixos-21.05;
    utils = {
      url = github:yatima-inc/nix-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, lean, utils, nixpkgs }:
    let
      supportedSystems = [
        # "aarch64-linux"
        # "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      inherit (utils) lib;
    in
    lib.eachSystem supportedSystems (system:
      let
        leanPkgs = lean.packages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (lib.${system}) buildCLib concatStringsSep;
        includes = 
          [ "${pkgs.openssl.dev}/include" "${leanPkgs.lean-bin-tools-unwrapped}/include" ./bindings ];
        INCLUDE_PATH = concatStringsSep ":" includes;
        libssl = (pkgs.openssl.out // {
          name = "lib/libssl.so";
          linkName = "ssl";
          libName = "libssl.so";
          __toString = d: "${d.out}/lib";
        });
        c-shim = buildCLib {
          updateCCOptions = d: d ++ (map (i: "-I${i}") includes);
          name = "lean-openssl-bindings";
          sharedLibDeps = [
            libssl
          ];
          src = ./bindings;
          extraDrvArgs = {
            linkName = "lean-openssl-bindings";
          };
        };
        c-shim-debug = c-shim.override {
          debug = true;
          updateCCOptions = d: d ++ (map (i: "-I${i}") includes) ++ [ "-O0" ];
        };
        name = "OpenSSL";  # must match the name of the top-level .lean file
        project = leanPkgs.buildLeanPackage
          {
            inherit name;
            # deps = [ lean-ipld.project.${system} ];
            # Where the lean files are located
            nativeSharedLibs = [ libssl c-shim ];
            src = ./src;
          };
        project-debug = project.override {
          debug = true;
          nativeSharedLibs = [ libssl c-shim-debug ];
        };
        test = leanPkgs.buildLeanPackage
          {
            name = "Tests";
            deps = [ project ];
            # Where the lean files are located
            src = ./test;
          };
        test-debug = test.override {
          debug = true;
          deps = [ project-debug ];
        };
        joinDepsDerivationns = getSubDrv:
          pkgs.lib.concatStringsSep ":" (map (d: "${getSubDrv d}") ([ project ] ++ project.allExternalDeps));
      in
      {
        inherit project test;
        packages = {
          ${name} = project.executable;
          test = test.executable;
          test-debug = test-debug.executable;
        };

        checks.test = test.executable;

        defaultPackage = self.packages.${system}.${name};
        devShell = pkgs.mkShell {
          inputsFrom = [ project.executable ];
          buildInputs = with pkgs; [
            leanPkgs.lean
          ];
          LEAN_PATH = joinDepsDerivationns (d: d.modRoot);
          LEAN_SRC_PATH = joinDepsDerivationns (d: d.src);
          C_INCLUDE_PATH = INCLUDE_PATH;
          CPLUS_INCLUDE_PATH = INCLUDE_PATH;
        };
      });
}
