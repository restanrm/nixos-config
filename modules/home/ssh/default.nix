{
  context,
  lib,
  ...
}: {
  imports = [./home.nix] ++ lib.optional context.work ./work.nix;
}
