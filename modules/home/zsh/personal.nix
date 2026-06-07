{pkgs, ...}: {
  # Personal-specific zsh configuration
  programs.zsh = {
    # Personal-specific aliases
    shellAliases = {
      sway = "XKB_DEFAULT_LAYOUT=fr XKB_DEFAULT_VARIANT=bepo sway";
    };

    # Personal-specific environment variables
    sessionVariables = {
      VAULT_ADDR = "https://vault.restanrm.fr";
      SOPS_AGE_RECIPIENTS = "age10jesetp8dl5rz66mndmwzurgqt94pp8paarmq8tpmmkf66g42a6qkdcy54,age1gq75rrvkzxqj04hzly9zdn6mzmxuk4a85u2trcn2jen9axx3s4ls88rrsm";
    };
  };
}
