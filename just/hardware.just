set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list hardware

# Recover and rebind the AMD I2C touchpad controller (HP Victus 16).
restart-touchpad *args:
    @ysh scripts/hardware/restart-touchpad.ysh "$@"
