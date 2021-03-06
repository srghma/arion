{ pkgs, ... }:

let
  # To make some prebuilt derivations available in the vm
  preEval = import ../../src/nix/eval-docker-compose.nix {
    modules = [ ../../examples/minimal/arion-compose.nix ];
    inherit pkgs;
  };
in
{
  name = "arion-test";
  machine = { pkgs, lib, ... }: {
    environment.systemPackages = [
      pkgs.arion
      pkgs.docker-compose
    ];
    virtualisation.docker.enable = true;
    
    # no caches, because no internet
    nix.binaryCaches = lib.mkForce [];
    virtualisation.writableStore = true;
    virtualisation.pathsInNixDB = [
      # Pre-build the image because we don't want to build the world
      # in the vm.
      preEval.config.build.dockerComposeYaml
    ];
  };
  testScript = ''
    $machine->fail("curl localhost:8000");
    $machine->succeed("docker --version");
    $machine->succeed("cp -r ${../../examples/minimal} work && cd work && NIX_PATH=nixpkgs='${pkgs.path}' arion up -d");
    $machine->waitUntilSucceeds("curl localhost:8000");
  '';
}
