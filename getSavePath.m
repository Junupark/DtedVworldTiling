function filepath = getSavePath(opt)
    arguments
        opt.basepath = pwd
        opt.type char {mustBeMember(opt.type, {'satellite', 'abstract', 'dted'})} = 'satellite'
        opt.zoom {mustBeInteger}
        opt.x {mustBeInteger}
        opt.y {mustBeInteger}
        opt.extension = "png"
    end
    
    filedir = strcat(opt.basepath, filesep, opt.type, ...
                    filesep, num2str(opt.zoom), ...
                    filesep, num2str(opt.x));

    filename = strcat(num2str(opt.y), ".", opt.extension);
    
    if ~exist(filedir, 'dir')
        mkdir(filedir)
    end
    
    filepath = strcat(filedir, filesep, filename);
end