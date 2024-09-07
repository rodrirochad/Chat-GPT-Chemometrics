function hyperspectralPCAApp
    % Create the GUI figure
    f = figure('Name', 'Hyperspectral PCA Analysis', 'Position', [100, 100, 800, 600]);
    
    % Add UI components
    uicontrol('Style', 'pushbutton', 'String', 'Load Data', 'Position', [10, 550, 100, 30], 'Callback', @loadDataCallback);
    uicontrol('Style', 'pushbutton', 'String', 'Perform PCA', 'Position', [120, 550, 100, 30], 'Callback', @performPCACallback);
    uicontrol('Style', 'text', 'String', 'Select Number of PCs:', 'Position', [230, 550, 120, 30]);
    pcNumber = uicontrol('Style', 'edit', 'String', '5', 'Position', [360, 550, 50, 30]);
    
    % Axes for displaying results
    ax1 = axes('Parent', f, 'Position', [0.1, 0.3, 0.35, 0.2]);
    ax2 = axes('Parent', f, 'Position', [0.55, 0.3, 0.35, 0.2]);
    ax3 = axes('Parent', f, 'Position', [0.1, 0.05, 0.35, 0.2]);
    
    % Data variables
    hsiData = [];
    pcaResults = [];
    
    function loadDataCallback(~, ~)
        % Load hyperspectral data
        [file, path] = uigetfile('*.mat', 'Select Hyperspectral Data');
        if isequal(file, 0)
            return;
        end
        data = load(fullfile(path, file));
        hsiData = data.hsi; % Adjust field name based on your data structure
        msgbox('Data Loaded Successfully');
    end

    function performPCACallback(~, ~)
        if isempty(hsiData)
            errordlg('No data loaded');
            return;
        end
        numPCs = str2double(pcNumber.String);
        if isnan(numPCs) || numPCs <= 0
            errordlg('Invalid number of PCs');
            return;
        end
        
        % Reshape data and perform PCA
        [rows, cols, bands] = size(hsiData);
        reshapedData = reshape(hsiData, rows * cols, bands);
        [coeff, score, ~] = pca(reshapedData);
        pcaResults.score = score;
        pcaResults.coeff = coeff;
        pcaResults.numPCs = numPCs;
        
        % Display the first 3 PC score images
        axes(ax1);
        imagesc(reshape(score(:, 1), rows, cols));
        title('PC 1');
        axes(ax2);
        imagesc(reshape(score(:, 2), rows, cols));
        title('PC 2');
        axes(ax3);
        imagesc(reshape(score(:, 3), rows, cols));
        title('PC 3');
        
        % Plot the loadings
        figure;
        hold on;
        for i = 1:numPCs
            plot(coeff(:, i), 'DisplayName', ['PC ' num2str(i)]);
        end
        hold off;
        legend show;
        title('Loadings');
        
        % Display false color image
        falseColorImage = cat(3, reshape(score(:, 1), rows, cols), reshape(score(:, 2), rows, cols), reshape(score(:, 3), rows, cols));
        figure;
        imshow(falseColorImage, []);
        title('False Color Image');
    end
end
