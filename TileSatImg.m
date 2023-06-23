function TileSatImg(opt)
    arguments
        opt.type char {mustBeMember(opt.type, {'satellite','abstract','blahblah'})} = 'satellite'
        opt.path_api_key
        opt.min_zoom {mustBeInteger, mustBeInRange(opt.min_zoom, 1, 18)} = 1;
        opt.max_zoom {mustBeInteger, mustBeInRange(opt.max_zoom, 1, 18)} = 18;
        opt.left_upper_corner (2,1) = [36; 127]
        opt.right_lower_corner (2,1) = [36; 127]
        opt.extension char {mustBeMember(opt.extension, {'png','jpg','bmp'})} = 'png'
    end
    assert(isfield(opt, 'path_api_key'), "VWORLD API KEY FILE REQUIRED");
    api_key = fileread(opt.path_api_key);
    
    switch opt.type
        case "satellite"
            query_type = "PHOTO";
    end
    
    for zoom = opt.min_zoom:opt.max_zoom
        [~, x_min, y_min] = mapSlippyIndex(opt.left_upper_corner, zoom, true);
        [~, x_max, y_max] = mapSlippyIndex(opt.right_lower_corner, zoom, true);
        for x = x_min:x_max
            for y = y_min:y_max
                query_pos = mapSlippyIndex([x;y], zoom, false);

                img = webread(getQueryURL('api_key', api_key, 'type', query_type, 'query_pos', query_pos, 'zoom', zoom));
                % some post process

                imwrite(img, getSavePath('zoom', zoom, 'x', 5, 'y', 1, 'type', opt.type), 'png');
            end
        end
    end
end