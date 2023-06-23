function url = getQueryURL(opt)
    arguments
        opt.host_url = "http://api.vworld.kr/req/image?service=image&request=getmap";
        opt.api_key
        opt.type = "PHOTO"
        opt.query_pos (2,1)
        opt.zoom
        opt.size (2,1) = [256,256]
        opt.latlon logical = true % query_pos: [lat;lon](=true), [lon;lat](=false)
    end
    if ~opt.latlon
        opt.query_pos = flip(opt.query_pos);
    end
    
    url = strcat(opt.host_url, ...
                    "&key=", opt.api_key, ...
                    "&center=", sprintf("%f,%f",opt.query_pos(2), opt.query_pos(1)), ...
                    "&zoom=", num2str(opt.zoom), ...
                    "&size=", sprintf("%d,%d",opt.size(1), opt.size(2)), ...
                    "&basemap=", opt.type);
end