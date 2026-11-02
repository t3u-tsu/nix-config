set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list system

# Build and activate the system configuration, making it the boot default.
switch *args:
    nh os switch . "$@"

# Build and activate the system configuration without adding it to the bootloader.
test *args:
    nh os test . "$@"

# Build the system configuration and make it the boot default without activating now.
boot *args:
    nh os boot . "$@"

# Build the system configuration without activating.
build *args:
    nh os build . "$@"

# Preview system changes without applying (dry run).
diff *args:
    nh os switch . --dry "$@"

# Clean old generations across all profiles.
gc *args:
    nh clean all "$@"

# Rollback to the previous generation.
rollback *args:
    nh os rollback "$@"

# Show generations information.
info *args:
    nh os info "$@"
