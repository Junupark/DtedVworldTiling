function [tuple, x_elem, y_elem] = mapSlippyIndex(input, zoom, to_tile_numbers)
    % (1) lat/lon > x/y
    % (2) x/y > > lat/lon
    
    n = 2^zoom;
    if to_tile_numbers
        x_elem = floor(n * ((input(2) + 180) / 360));
        y_elem = floor(0.5 * n * (1 - (log(tand(input(1)) + secd(input(1))) / pi)));
    else
        x_elem = rad2deg(atan(sinh(pi * (1 - 2 * input(2) / n))));
        y_elem = input(1) / n * 360 - 180;
    end
    tuple = [x_elem;y_elem];
end