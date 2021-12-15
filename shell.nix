{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
    buildInputs = [
      pkgs.neovim
      pkgs.stylua
      pkgs.luajitPackages.busted
    ];
}
