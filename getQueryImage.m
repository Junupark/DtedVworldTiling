function img = getQueryImage(url)
    try
        img = webread(url);
        img = img(41:296, :, :);
    catch
        img = zeros(256, 256, 3);
    end
end