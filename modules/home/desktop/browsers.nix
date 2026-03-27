{ config, osConfig, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.my.home.desktop.browsers;
in {
  options.my.home.desktop.browsers = {
    enable = mkEnableOption "Web browsers";
    zen.enable = mkOption {
      type = types.bool;
      default = true;
    };
    chromium.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = optional cfg.chromium.enable pkgs.chromium;

    programs.zen-browser = mkIf cfg.zen.enable {
      enable = true;
      nativeMessagingHosts = [ pkgs.bitwarden-desktop ];
      
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never"; # or "always"
        
        # Declarative Extensions via Policy (Reliable way)
        ExtensionSettings = {
          "*".installation_mode = "allowed"; # Allow manual installs too
          # uBlock Origin
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          # Bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
          # SponsorBlock
          "sponsorBlocker@ajay.app" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
            installation_mode = "force_installed";
          };
          # Keepa
          "amptra@keepa.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepa/latest.xpi";
            installation_mode = "force_installed";
          };
          # Tampermonkey
          "firefox@tampermonkey.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
            installation_mode = "force_installed";
          };
          # Video DownloadHelper
          "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/video-downloadhelper/latest.xpi";
            installation_mode = "force_installed";
          };
          # Wappalyzer
          "wappalyzer@crunchlabz.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
            installation_mode = "force_installed";
          };
          # YouTube NonStop (User requested to KEEP)
          "{0d7cafdd-501c-49ca-8ebb-e3341caaa55e}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-nonstop/latest.xpi";
            installation_mode = "force_installed";
          };
          # YouTube Screenshot
          "{d8b32864-153d-47fb-93ea-c273c4d1ef17}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/take-youtube-screenshots/latest.xpi";
            installation_mode = "force_installed";
          };
          # LINE (User requested to KEEP)
          "LINEPorted@FoxRefire" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/line-on-browser/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };

      # Create a default profile named after the user
      profiles.${osConfig.my.user.name} = {
        isDefault = true;
        
        search = {
          default = "google";
          force = true;
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "https://nixos.org/favicon.png";
              definedAliases = [ "@n" ];
            };
            "NixOS Wiki" = {
              urls = [{ template = "https://wiki.nixos.org/index.php?search={searchTerms}"; }];
              icon = "https://wiki.nixos.org/favicon.png";
              definedAliases = [ "@nw" ];
            };
            "MyNixOS" = {
              urls = [{ template = "https://mynixos.com/search?q={searchTerms}"; }];
              definedAliases = [ "@my" ];
            };
            "GitHub" = {
              urls = [{ template = "https://github.com/search?q={searchTerms}&type=code"; }];
              icon = "https://github.com/favicon.ico";
              definedAliases = [ "@gh" ];
            };
            "Google Translate" = {
              urls = [{ template = "https://translate.google.com/?sl=auto&tl=ja&text={searchTerms}&op=translate"; }];
              icon = "https://www.gstatic.com/lamda/images/favicon_v2_78462ef77d0c794346ad.png";
              definedAliases = [ "@tr" ];
            };
            "google".metaData.alias = "@g"; # builtin engines
          };
        };

        containers = {
          "Personal" = { id = 1; icon = "fingerprint"; color = "green"; };
          "School" = { id = 2; icon = "circle"; color = "yellow"; };
          "Work" = { id = 3; icon = "briefcase"; color = "blue"; };
        };

        settings = {
          # General UI/UX
          "extensions.autoDisableScopes" = 0;
          "browser.aboutConfig.showWarning" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.newtabpage.enabled" = false; # Clean new tab
          "browser.startup.page" = 3; # Resume last session
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.bookmarks.addedImportButton" = false;
          
          # Disable Built-in Password Manager (Using Bitwarden)
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.generation.enabled" = false;
          "signon.management.page.breach-alerts.enabled" = false;
          "signon.showAutoCompleteFooter" = false;

          # Language & Localization
          "intl.accept_languages" = "ja-jp,ja,en-us,en";
          "intl.locale.requested" = "ja";
          
          # Zen Specific UI Tweaks
          "zen.view.compact.color-sidebar" = true;
          "zen.theme.content-element-separation" = 0;
          "zen.workspaces.show-workspace-indicator" = true;
          "zen.theme.essentials-favicon-bg" = true;
          
          # Zen Verified settings
          "zen.welcome-screen.seen" = true;
          "browser.aboutwelcome.enabled" = false;

          # Privacy & Security
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "dom.security.https_only_mode" = true;
          "network.cookie.cookieBehavior" = 0; # Allow all cookies
          "network.cookie.lifetimePolicy" = 0; # Keep until expired
          
                    # Performance
                    "gfx.webrender.all" = true;
                    "media.ffmpeg.vaapi.enabled" = true; # Hardware acceleration
                    
                    # Smooth Scrolling
                    "general.smoothScroll" = true;
                  };
          
                  # Noctalia Dynamic Theming Integration
                  userChrome = ''
                    /* Import Noctalia-generated colors */
                    @import url("file:///home/${osConfig.my.user.name}/.cache/noctalia/colors.css");
          
                    :root {
                      --zen-primary-color: var(--noctalia-primary) !important;
                      --zen-secondary-color: var(--noctalia-secondary) !important;
                    }
          
                    /* Match Zen UI with Noctalia colors */
                    #zen-sidebar-content {
                      background-color: var(--noctalia-surface) !important;
                    }
                    
                    .tab-content[selected="true"] {
                      background-color: var(--noctalia-primary-container) !important;
                      color: var(--noctalia-on-primary-container) !important;
                    }
                  '';
                };
              };
            };
          }
          
