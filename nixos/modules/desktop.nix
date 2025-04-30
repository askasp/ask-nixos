{ config, lib, pkgs, ... }:

{
  # Enable X11 windowing system and KDE Plasma 6
  services.xserver = {
    enable = true;
    
    # Enable the SDDM display manager
    displayManager.sddm.enable = true;
    
    # Enable Plasma 6
    desktopManager.plasma6.enable = true;
    
    # Configure keymap in X11
    layout = "us";
    xkbVariant = "";
  };

  # Enable sound with pipewire
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (for laptop)
  # services.xserver.libinput.enable = true;

  # Install useful desktop applications
  environment.systemPackages = with pkgs; [
    # Internet
    firefox
    thunderbird
    
    # Office
    libreoffice-qt
    
    # Graphics
    gimp
    
    # Utilities
    konsole
    dolphin
    ark
    kate
    kcalc
    kdeconnect
    spectacle # Screenshot tool
    
    # Themes and customization
    breeze-icons
    breeze-gtk
    
    # Media
    vlc
    
    # System tools
    filelight
    kinfocenter
    plasma-systemmonitor
  ];
  
  # Enable Flatpak for additional applications (optional)
  services.flatpak.enable = true;
  
  # Enable fonts
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  # Enable CUPS for printing
  services.printing.enable = true;
  
  # Enable NetworkManager for network configuration
  networking.networkmanager.enable = true;
  
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
} 