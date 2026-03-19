% Rotate the minimum angle for the straightening 

function angle_norm = normalise_angle(angle)
    angle_norm = mod(angle + 45, 90) - 45;
end
