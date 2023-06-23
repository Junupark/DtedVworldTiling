%%
% ======================================= %
% ============= DTED Tiling ============= %
% ======================================= %

% typical usage. (default) Korean peninsula
TileDTED('min_zoom', 1, 'max_zoom', 13);

% designating tiling range
% TileDTED('min_zoom', 7, 'max_zoom', 11, 'left_upper_corner', [38, 125], 'right_lower_corner', [34, 128]);



%%
% ======================================= %
% ========== Sat. Image Tiling ========== %
% ======================================= %
TileSatImage('min_zoom', 7, 'max_zoom', 8);