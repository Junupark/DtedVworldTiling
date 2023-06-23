% Maintainer: Junwoo Park <vividlibra@gmail.com>

classdef DTEDTile < handle
    % SRTM/COPERNICUS Tiff file only;
    % saved as we see it on the map
    %    Y -->
    % X DB(1,1) DB(1,2) ...
    % | DB(2,1) ...
    % | DB(3,1) ...
    % V DB(4,1) ...
    % .   ...
    % .   ...
    % . [ORIGIN]
    
    % Origin is set as left-lower corner
    % Tile covers [1deg * 1deg]
    properties (Access = private)
        data
    end
    properties
        origin_lat_deg
        origin_lon_deg
        interp_method
        
        range1_sec % in sec
        range2_sec % in sec
        
        deg2sec
        
        default_height
    end
    methods
        function self = DTEDTile(data, opt)
            arguments
                data (3601, 3601) double {mustBeNumeric}
                opt.origin_lat double {mustBeInRange(opt.origin_lat, 33, 37)}
                opt.origin_lon double {mustBeInRange(opt.origin_lon, 126, 129)}
                opt.radian logical = false
                opt.interp_method (1,:) char {mustBeMember(opt.interp_method,{'linear','cubic','spline'})} = 'linear'
                opt.default_height double {mustBeNumeric} = -10
            end
            self.data = data;
            if opt.radian
                self.origin_lat_deg = rad2deg(opt.origin_lat);
                self.origin_lon_deg = rad2deg(opt.origin_lon);
            else
                self.origin_lat_deg = opt.origin_lat;
                self.origin_lon_deg = opt.origin_lon;
            end
            self.interp_method = opt.interp_method;
            self.deg2sec = 3600;
            self.default_height = opt.default_height;
            self.range1_sec = linspace(self.deg2sec*(self.origin_lat_deg+1), self.deg2sec*self.origin_lat_deg, 1*self.deg2sec+1); % <reversed>
            self.range2_sec = linspace(self.deg2sec*self.origin_lon_deg, self.deg2sec*(self.origin_lon_deg+1), 1*self.deg2sec+1);
        end
        
        function self = SetInterpMethod(self, method)
            arguments
                self %{mustBeA(self, 'DTEDTile')}
                method (1,:) char {mustBeMember(method,{'linear','cubic','spline'})} = 'linear'
            end
            self.interp_method = method;
        end
        
        function pos_deg = idx2pos(self, idx)
            arguments
                self %{mustBeA(self, 'DTEDTile')}
                idx (1,:) {mustBeInteger, mustBePositive}
            end
            assert(length(idx)==2 && idx(1) <= length(self.range1_sec) &&  idx(2) <= length(self.range2_sec))
            
            pos_deg = [self.range1_sec(idx(1)); self.range2_sec(idx(2))]/self.deg2sec;
        end
        
        function idx = pos2idx(self, pos_deg)
%             arguments
%                 self %{mustBeA(self, 'DTEDTile')}
%                 pos_deg %(2,:)
%             end
            idx1 = floor((self.origin_lat_deg+1-pos_deg(1)) * self.deg2sec); % [i,i+1), [0,3599]
            idx2 = floor((pos_deg(2) - self.origin_lon_deg) * self.deg2sec); % [i,i+1), [0,3599]
            idx = [idx1+1; idx2+1];
        end
        
%         function [h00, h10, h01, h11, f1, f2] = InfoCell(self, query_pos, opt)
%             arguments
%                 self
%                 query_pos %(2,:)
%                 opt.radian = false %logical = false
%             end
%             if opt.radian
%                 query_pos_deg = rad2deg(query_pos);
%             else
%                 query_pos_deg = query_pos;
%             end
        function [h00, h10, h01, h11, f1, f2] = InfoCell(self, query_pos_deg)
            idx = self.pos2idx(query_pos_deg);
%             idx(idx==3601) = 3600;
            idx(idx>3600) = 3600;
            
            f1 = self.range1_sec(idx(1)) - query_pos_deg(1) * self.deg2sec; % [0,1)
            f2 = query_pos_deg(2) * self.deg2sec - self.range2_sec(idx(2)); % [0,1)
            
            h00 = self.data(idx(1),     idx(2));
            h10 = self.data(idx(1)+1,   idx(2));
            h01 = self.data(idx(1),     idx(2)+1);
            h11 = self.data(idx(1)+1,   idx(2)+1);
        end
        
%         function h = ElevationAt(self, pos, opt)
%             arguments
%                 self %{mustBeA(self, 'DTEDTile')}
%                 pos %(2,:) %double
%                 opt.radian = false %logical = false
%             end
%             
%             if opt.radian
%                 pos = rad2deg(pos);
%             end
        function h = ElevationAt(self, pos)
            if self.WithinCoverage(pos)
                [h00, h10, h01, h11, f1, f2] = self.InfoCell(pos);
                
                h_0 = (1-f1)*h00 + f1*h10;
                h_1 = (1-f1)*h01 + f1*h11;
                h = (1-f2)*h_0 + f2*h_1;
            else
                warning(['query position out of bound, [lat: ', num2str(pos(1)), 'lon: ', num2str(pos(2)), ']']);
                h = self.default_height;
            end
%             h = double(h);
        end
        
%         function h = ElevationAt_(self, pos, opt)
%             % interpn takes too much time
%             arguments
%                 self %{mustBeA(self, 'DTEDTile')}
%                 pos (2,1) {mustBeNumeric}
%                 opt.radian logical = false
%             end
%             warning('Deprecated, use {DTEDTile}.ElevationAt(pos, opt) instead');
%             
%             if opt.radian
%                 pos = rad2deg(pos);
%             end
%             query_lat_deg = pos(1);
%             query_lon_deg = pos(2);
%             
%             if self.WithinCoverage([query_lat_deg, query_lon_deg])
%                 h = interpn(self.range1_sec, self.range2_sec, self.data, ...
%                     self.deg2sec*query_lat_deg, self.deg2sec*query_lon_deg, self.interp_method);
%             else
%                 warning(['query position out of bound, [lat: ', num2str(query_lat_deg), 'lon: ', num2str(query_lon_deg), ']']);
%                 h = self.default_height;
%             end
%             h = double(h);
%         end
        
        function [M, C] = PlotContour(self, opt)
            arguments
                self {mustBeA(self, 'DTEDTile')}
                opt.left_lower (1,:) = [self.origin_lat_deg, self.origin_lon_deg]
                opt.right_upper (1,:) = [self.origin_lat_deg+1, self.origin_lon_deg+1]
                opt.deg_scale logical = true
                opt.showtext logical = false
                opt.n_contour {mustBePositive, mustBeInteger} = 10
                opt.new_figure logical = true
                opt.fill logical = false
            end
            assert(WithinCoverage(self, opt.left_lower) && WithinCoverage(self, opt.right_upper))
            if opt.radian
                opt.left_lower = rad2deg(opt.left_lower);
                opt.right_upper = rad2deg(opt.right_upper);
            end
            idx_left_lower = self.pos2idx(opt.left_lower);
            idx_right_upper = self.pos2idx(opt.right_upper);
            idx_lat = idx_right_upper(1):idx_left_lower(1);
            idx_lon = idx_left_lower(2):idx_right_upper(2);
            if opt.deg_scale
                lat = linspace(opt.right_upper(1), opt.left_lower(1), length(idx_lat));
                lon = linspace(opt.left_lower(2), opt.right_upper(2), length(idx_lon));
            else
                lat = idx_lat;
                lon = idx_lon;
            end
            [LAT, LON] = ndgrid(lat, lon);
            
            if opt.new_figure
                figure;
            else
                hold on;
            end
            
            if opt.fill
                [M, C] = contourf(LAT, LON, self.data(idx_lat, idx_lon), opt.n_contour, 'showtext', opt.showtext);
            else
                [M, C] = contour(LAT, LON, self.data(idx_lat, idx_lon), opt.n_contour, 'showtext', opt.showtext);
            end
            xlabel('Latitute (deg)'); ylabel('Longitude (deg)');
            set(C.Parent, 'xdir','reverse'); % Parent: axes handle
            set(C.Parent, 'DataAspectRatio', [1, 1, 1]);
            set(C, 'EdgeColor', 'None');
            view(C.Parent, 90, 90);
        end
        
%         function flag = WithinCoverage(self, query_pos, opt)
%             arguments
%                 self %{mustBeA(self, 'DTEDTile')}
%                 query_pos %(1,:)
%                 opt.radian = false %logical = false
%             end
%             assert(length(query_pos)==2)
%             if opt.radian
%                 query_lat_deg = rad2deg(query_pos(1));
%                 query_lon_deg = rad2deg(query_pos(2));
%             else
%                 query_lat_deg = query_pos(1);
%                 query_lon_deg = query_pos(2);
%             end
        function flag = WithinCoverage(self, query_pos_deg)
            query_lat_deg = query_pos_deg(1);
            query_lon_deg = query_pos_deg(2);
            flag = ~(query_lat_deg < self.origin_lat_deg || query_lat_deg > self.origin_lat_deg+1 || query_lon_deg < self.origin_lon_deg || query_lon_deg > self.origin_lon_deg+1);
        end
    end
end