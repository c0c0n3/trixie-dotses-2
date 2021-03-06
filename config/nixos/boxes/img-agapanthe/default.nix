#
# Main module for `img-agapanthe` config.
#
{ config, lib, pkgs, ... }:

{

  imports = [
    ../../modules/dotses
    ../../modules/generic
    ../../pkgs
    ./hidpi.nix            # TODO not working! stuck with 96 dpi
    ./wireless-input.nix   # TODO don't think I need this w/ GNOME?
  ];

  # By default Nix won't install packages that have a non-free software
  # license. We need a couple of those (see notes down below) so we have
  # to override the default setting to force Nix to install them.
  nixpkgs.config.allowUnfree = true;


  ##########  Core System Setup  ###############################################

  # Set host name and enable container networking.
  networking.hostName = "img-agapanthe";
  ext.containers.networking.enable = true;
  ext.containers.networking.nat-interface = "enp0s25";

  # X: use NVidia driver.
  services.xserver = {
    videoDrivers = [ "nvidia" ];  # requires allowUnfree
  };

  # Connect wireless keyboard and trackpad.
  # TODO don't think I need this w/ GNOME?
  ext.wireless-input.enable = true;

  # Tweak resolution cos X doesn't get it right on the HP ZBook.
  # ext.hidpi.enable = true;  # TODO not working! stuck with 96 dpi

  ##########  Desktop Setup  ###################################################

  # Create my usual admin user with initial password of `abc123` and build
  # a GNOME 3 desktop for him, with automatic login.
  ext.yougnomix = {
    enable = true;
    username = "andrea";
  };
  # TODO you have to run the script to install our GNOME config cos the
  # automated running of it on sys activation is currently broken!

  # Use Slim instead of GDM.
  # TODO switch back to GDM when they fix it.
  # GDM's currently broken, see:
  # - https://github.com/NixOS/nixpkgs/issues/24172
  # Me too, I get this error:
  #   gdm-3.22.0/libexec/gdm-x-session[1055]: (WW) xf86OpenConsole:
  #   VT_ACTIVATE failed: Operation not permitted
  # See also:
  # - https://bugzilla.redhat.com/show_bug.cgi?id=1335511
  #
  ext.gnomix.dmName = "slim";

  # Add custom key binding for Chrome.
  ext.gnomix.gsettings.keys.custom = [
    { name    = "Browser";
      command = "google-chrome-stable";
      binding = "<Super><Shift>w";
    }];

  # Install my usual fonts and tweak Spacemacs font.
  ext.fonts.font-pack.enable = true;
  ext.spacemacs.config.font.size = 22;

  ##########  Base Dev Env Setup  ##############################################

  ext.git.config.user = config.users.users.andrea;

  ext.java.dev.enable = true;

  ext.inkscape.config.users = [ config.users.users.andrea ];
  # NB manual step: copy one of the prefs files in config/inkscape/preferences
  # to ~/.config/inkscape/preferences.xml

  ext.haskell.dev = {
    enable = true;
    with-extra-hpkgs = ps: with ps; [
      here diagrams diagrams-graphviz diagrams-rasterific
    ];
  };

  ext.latex.dev.enable = true;

  environment.systemPackages = with pkgs; with config.ext.pkgs; [
    nix-repl
    google-chrome # requires allowUnfree
    # (samba.override { enablePrinting = true; }) system-config-printer
    # samba
    remmina
    inkscape
    zoom-us # requires allowUnfree
    graphviz
  ];

  # Open up OMERO ports and forward TCP packets to homer container.
  networking.firewall = with lib;
  let
    ports = [ 80 4064 ];
    ext-if = "enp0s25";
    container-ip = "10.233.1.2";
    cmd = i : d : p :
    ''
      iptables -t nat -A PREROUTING -i ${i} -p tcp --dport ${p} -j DNAT --to-dest ${d}
    '';
    cmds = concatMapStrings (cmd ext-if container-ip) (map toString ports);
  in {
    enable = true;
    extraCommands = cmds;
    allowedTCPPorts = ports;
  };

/*
  services.printing.enable = true;
  services.printing.extraConf = ''
    LogLevel debug
  '';
  services.printing.drivers = [ (import ./pkgs/cups/toshiba-e-studio5005ac) ];
  services.samba.enable = true;
  */
}
