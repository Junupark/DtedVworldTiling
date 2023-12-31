function [dteds] = TileDTED(opt)
    arguments
        opt.min_zoom {mustBeInteger, mustBeInRange(opt.min_zoom, 1, 18)} = 1;
        opt.max_zoom {mustBeInteger, mustBeInRange(opt.max_zoom, 1, 18)} = 18;
        opt.left_upper_corner (2,1) = [38; 126]
        opt.right_lower_corner (2,1) = [34; 130]
        opt.rel_path_to_database char = './DB/SRTM/Tiff'
    end
%     warning off
    addpath(opt.rel_path_to_database);
%     addpath('../../particle filter trn/DB/SRTM/Tiff/'); % local
    
    corner_lat  = 33:37;
    corner_lon  = 126:129;
    n_tile_lat  = length(corner_lat);
    n_tile_lon  = length(corner_lon);
    n_dteds     = n_tile_lat * n_tile_lon;
    
    fprintf("Collecting DTEDs..\n");
    fprintf(" - progress: %s\n", progress());
    idx = 0;
    for lon = corner_lon
        for lat = corner_lat
            idx = idx+1;
            filename = sprintf("n%2d_e%3d_1arc_v3.tif",lat,lon);
            try
                data = read(Tiff(filename, 'r'));
                dted = DTEDTile(data, 'origin_lat', lat, 'origin_lon', lon, 'radian', false, 'interp_method', 'linear', 'default_height', 0);
                clear data;
            catch 
                dted = DTEDTile(0, 'origin_lat', lat, 'origin_lon', lon, 'default_height', 0);
                warning("no such DTED");
            end
            dteds(idx) = dted;
            fprintf("\b\b\b\b\b\b\b\b\b\b\b%s\n", progress(idx/n_dteds));
        end
    end
    dteds = reshape(dteds, n_tile_lat, n_tile_lon);
    fprintf("Done!\n\n");
    
    for zoom = opt.min_zoom:opt.max_zoom
        fprintf("Zoom level [%d] begin!\n", zoom);
        [~, x_min, y_min] = mapSlippyIndex(opt.left_upper_corner, zoom, true);
        [~, x_max, y_max] = mapSlippyIndex(opt.right_lower_corner, zoom, true);
        
        fprintf(" - x:[%d, %d], y:[%d, %d]\n", x_min, x_max, y_min, y_max);
        fprintf(" - progress: %s\n", progress());
        for x = x_min:x_max
            for y = y_min:y_max
                pos_lu = mapSlippyIndex([x;y], zoom, false);
                pos_rd = mapSlippyIndex([x+1;y+1], zoom, false);
                
                LAT = linspace(pos_lu(1), pos_rd(1), 257);
                LON = linspace(pos_lu(2), pos_rd(2), 257);
                
                % ver1: plain iteration
%                 elevation_map = zeros(256,256);
%                 for u = 1:256
%                     for v = 1:256
%                         query_pos = [LAT(u); LON(v)];
%                         [oob, idx_dted_lat, idx_dted_lon] = associateDTED(query_pos, corner_lat, corner_lon);
%                         if oob
%                             elevation_map(u,v) = 0;
%                         else
%                             dted = dteds(idx_dted_lat, idx_dted_lon);
%                             elevation_map(u,v) = dted.ElevationAt(query_pos);
%                         end
%                     end
%                 end

                % ver2: intermediate vectorization
                [LAT, LON] = ndgrid(LAT(1:256), LON(1:256));
                position_map = cat(3, LAT, LON);
                [oob_map, idx_dted_lat_map, idx_dted_lon_map] = associateDTEDMap(position_map, corner_lat, corner_lon);
                elevation_map = zeros(256,256);
                for u = 1:256
                    for v = 1:256
                        if oob_map(u,v)
                            elevation_map(u,v) = 0;
                        else
                            dted = dteds(idx_dted_lat_map(u,v), idx_dted_lon_map(u,v));
                            elevation_map(u,v) = dted.ElevationAt(position_map(u,v,:));
                        end
                    end
                end
                
                % ver3: (TBA) advanced vectorization
                
                imwrite(encodeElevation(elevation_map), getSavePath('zoom', zoom, 'x', x, 'y', y, 'type', 'dted'), 'png');
            end
            fprintf("\b\b\b\b\b\b\b\b\b\b\b%s\n",progress((x-x_min+1)/(x_max-x_min+1)));
        end
        fprintf("Zoom level [%d] completed!\n\n", zoom);
    end
end

% encode terrain elevation into r-g-b according to:
% https://docs.mapbox.com/data/tilesets/guides/access-elevation-data/#mapbox-terrain-rgb
function rgb = encodeElevation(elevation_meter)
    e = round(10.*(elevation_meter + 1e4));
    b = mod(e, 256);
    e = (e-b)/256;
    g = mod(e, 256);
    e = (e-g)/256;
    r = mod(e, 256);
    rgb(:, :, 1) = r;
    rgb(:, :, 2) = g;
    rgb(:, :, 3) = b;
    rgb = rgb/255;
    % rgb = 0.00390625*rgb; % /256
end

% which DTED should I access to in order to correctly get terrain elevation given the position
function [out_of_bound, idx_dted_lat, idx_dted_lon] = associateDTED(pos, corner_lat, corner_lon)
    lat = pos(1);
    lon = pos(2);
    out_of_bound = lat < corner_lat(1) || lat > corner_lat(end)+1 || lon < corner_lon(1) || lon > corner_lon(end)+1;
    if ~out_of_bound
        idx_dted_lat = floor(lat - corner_lat(1))+1;
        idx_dted_lon = floor(lon - corner_lon(1))+1;
    else
        idx_dted_lat = nan;
        idx_dted_lon = nan;
    end
end

% which DTED should I access to in order to correctly get terrain elevations given map of positions
function [out_of_bound, idx_dted_lat, idx_dted_lon] = associateDTEDMap(pos_map, corner_lat, corner_lon)
    lat = pos_map(:,:,1);
    lon = pos_map(:,:,2);
    out_of_bound = lat < corner_lat(1) | lat > corner_lat(end)+1 | lon < corner_lon(1) | lon > corner_lon(end)+1;
    idx_dted_lat = ~out_of_bound.*(floor(lat - corner_lat(1))+1);
    idx_dted_lon = ~out_of_bound.*(floor(lon - corner_lon(1))+1);
end

% progress bar as a string, e.g., 20% = ">>........", 50% = ">>>>>....."
function progress_string = progress(p)
    arguments
        p {mustBeInRange(p, 0, 1)} = 0
    end
    n = floor(p*10);
    progress_string = strcat(repmat('>', 1, n), repmat('.', 1, 10-n));
end