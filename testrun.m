%%
% ======================================= %
% ============= DTED Tiling ============= %
% ======================================= %

% typical usage. (default) Korean peninsula
TileDTED('min_zoom', 14, 'max_zoom', 14);

% designating tiling range
% TileDTED('min_zoom', 7, 'max_zoom', 11, 'left_upper_corner', [38, 125], 'right_lower_corner', [34, 128]);



%%
% ======================================= %
% ========== Sat. Image Tiling ========== %
% ======================================= %

% must be equipped with a personlized api key as a file, e.f., ./vworld_api_key.txt
TileSatImage('min_zoom', 12, 'max_zoom', 12, 'path_api_key', './vworld_api_key.txt');