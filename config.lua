function GetFuelHologram(vehicle)
    return exports['LegacyFuel']:GetFuel(vehicle)
end

HologramSpeedConfig = {
    CommandName = 'hsp', -- don't put CAPS !
    Lang = {
        ['speedometer_reset'] = "Holographic speedometer theme ^5reset^r.",
        ['speedometer_set'] = "Holographic speedometer theme set to ^5",
        ['msg_err'] = "^1The the acceptable range for ^0%s ^1is ^0%f^1 ~ ^0%f^1, reset to default setting.^r",
        ['msg_succ'] = "^2Speedometer ^0%s ^2changed to ^0%f, %f, %f^r",
        ['invalid_theme'] = "^1Invalid theme! ^0Usage: /hsp theme <name>^r",
        ['offset_reset'] = "Offset reset. To change the offset, use: /hsp offset <X> <Y> <Z>",
        ['rotation_reset'] = "Rotation reset. To change the rotation, use: /hsp rotate <X> <Y> <Z>",
        ['toggle_hologram'] = "Toggle the holographic speedometer",
        ['allow_command'] = "Allow command: theme, offset, rotate",
        ['description_keymapping'] = "Change the key of the Speedometer",
        ['error_miss_stream'] = "^1Could not find `hologram_box_model` in the game... ^rHave you installed the resource correctly?",
     }
}