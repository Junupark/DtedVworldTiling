function TileSatImg(opt)
    arguments
        opt.type char {mustBeMember(opt.type, {'satellite','abstract','blahblah'})} = 'satellite'
        opt.path_api_key
        opt.min_zoom {mustBeInteger, mustBeInRange(opt.min_zoom, 1, 18)} = 1;
        opt.max_zoom {mustBeInteger, mustBeInRange(opt.max_zoom, 1, 18)} = 18;
        opt.left_upper_corner (2,1) = [38; 126]
        opt.right_lower_corner (2,1) = [34; 130]
        opt.extension char {mustBeMember(opt.extension, {'png','jpg','bmp'})} = 'png'
    end
    assert(isfield(opt, 'path_api_key'), "VWORLD API KEY FILE REQUIRED");
    api_key = fileread(opt.path_api_key);
    
    switch opt.type
        case "satellite"
            query_type = "PHOTO";
    end
    
    for zoom = opt.min_zoom:opt.max_zoom
        fprintf("Zoom level [%d] begin!\n", zoom);
        [~, x_min, y_min] = mapSlippyIndex(opt.left_upper_corner, zoom, true);
        [~, x_max, y_max] = mapSlippyIndex(opt.right_lower_corner, zoom, true);
        
        fprintf(" - x:[%d, %d], y:[%d, %d]\n", x_min, x_max, y_min, y_max);
        fprintf(" - progress: %s", progress());
        for x = x_min:x_max
            for y = y_min:y_max
                pos_lu = mapSlippyIndex([x;y], zoom, false);
                pos_rd = mapSlippyIndex([x+1;y+1], zoom, false);
                query_pos = 0.5*(pos_lu + pos_rd); % may need to adjust .5 pixel

                try
                    img = webread(getQueryURL('api_key', api_key, 'type', query_type, 'query_pos', query_pos, 'zoom', zoom, 'size', [300, 300]));
                    % some post process
                catch
                    img = zeros(256, 256, 3);
                end

                imwrite(img, getSavePath('zoom', zoom, 'x', x, 'y', y, 'type', opt.type), 'png');
            end
        fprintf("\b\b\b\b\b\b\b\b\b\b%s",progress((x-x_min+1)/(x_max-x_min+1)));
        end
        fprintf("\nZoom level [%d] completed!\n\n", zoom);
    end
end

function progress_string = progress(p)
    arguments
        p {mustBeInRange(p, 0, 1)} = 0
    end
    n = floor(p*10);
    progress_string = strcat(repmat('>', 1, n), repmat('.', 1, 10-n));
end