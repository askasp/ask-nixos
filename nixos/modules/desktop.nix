{ config, lib, pkgs, ... }:

{
  # Enable X11 windowing system 
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "";
  
  # Enable the SDDM display manager (moved out of xserver hierarchy)
  services.displayManager.sddm.enable = true;
  
  # Enable Plasma 6 (moved out of xserver hierarchy)
  services.desktopManager.plasma6.enable = true;

  # Enable audio with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (for laptop)
  # services.libinput.enable = true;

  # Install useful desktop applications
  environment.systemPackages = with pkgs; [
    # Internet
    firefox
    thunderbird
    
    # Office
    libreoffice-qt
    
    # Graphics
    gimp
    
    # KDE/Plasma applications (using correct package paths)
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.kdeconnect-kde
    kdePackages.spectacle # Screenshot tool
    
    # Themes and customization
    kdePackages.breeze-icons
    kdePackages.breeze-gtk
    
    # Media
    vlc
    
    # System tools
    kdePackages.filelight
    kdePackages.kinfocenter
    kdePackages.plasma-systemmonitor
  ];
  
  # Enable Flatpak for additional applications (optional)
  services.flatpak.enable = true;
  
  # Enable fonts
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
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