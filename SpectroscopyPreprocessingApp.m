classdef SpectroscopyPreprocessingApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        LoadDataButton             matlab.ui.control.Button
        BinSizeEditFieldLabel      matlab.ui.control.Label
        BinSizeEditField           matlab.ui.control.NumericEditField
        ApplyBinningButton         matlab.ui.control.Button
        LambdaEditFieldLabel       matlab.ui.control.Label
        LambdaEditField            matlab.ui.control.NumericEditField
        PEditFieldLabel            matlab.ui.control.Label
        PEditField                 matlab.ui.control.NumericEditField
        ApplyAsLSButton            matlab.ui.control.Button
        ExportDataButton           matlab.ui.control.Button
        RawDataAxes                matlab.ui.control.UIAxes
        PreprocessedDataAxes       matlab.ui.control.UIAxes
    end

    properties (Access = private)
        DataMatrix % Matrix containing the input data
        PreprocessedMatrix % Matrix containing the preprocessed data
    end

    methods (Access = private)

        function loadData(app)
            [file, path] = uigetfile('*.mat');
            if isequal(file,0)
                return;
            else
                data = load(fullfile(path, file));
                app.DataMatrix = data.data;
                plot(app.RawDataAxes, app.DataMatrix');
                title(app.RawDataAxes, 'Raw Data');
                xlabel(app.RawDataAxes, 'Wavelength');
                ylabel(app.RawDataAxes, 'Intensity');
            end
        end

        function binningPreprocessing(app)
            binSize = app.BinSizeEditField.Value;
            if isempty(app.DataMatrix)
                uialert(app.UIFigure, 'No data loaded', 'Error');
                return;
            end
            if binSize < 1 || binSize > size(app.DataMatrix, 2)
                uialert(app.UIFigure, 'Invalid bin size', 'Error');
                return;
            end
            % Perform binning
            numBins = floor(size(app.DataMatrix, 2) / binSize);
            app.PreprocessedMatrix = zeros(size(app.DataMatrix, 1), numBins);
            for i = 1:numBins
                app.PreprocessedMatrix(:, i) = mean(app.DataMatrix(:, (i-1)*binSize+1:i*binSize), 2);
            end
            plot(app.PreprocessedDataAxes, app.PreprocessedMatrix');
            title(app.PreprocessedDataAxes, 'Binned Data');
            xlabel(app.PreprocessedDataAxes, 'Binned Wavelength');
            ylabel(app.PreprocessedDataAxes, 'Intensity');
        end

        function baselineCorrection(app)
            if isempty(app.PreprocessedMatrix)
                uialert(app.UIFigure, 'No preprocessed data', 'Error');
                return;
            end
            lambda = app.LambdaEditField.Value;
            p = app.PEditField.Value;
            % Apply baseline correction
            for i = 1:size(app.PreprocessedMatrix, 1)
                app.PreprocessedMatrix(i, :) = asls(app.PreprocessedMatrix(i, :), lambda, p);
            end
            plot(app.PreprocessedDataAxes, app.PreprocessedMatrix');
            title(app.PreprocessedDataAxes, 'Binned and Baseline Corrected Data');
            xlabel(app.PreprocessedDataAxes, 'Binned Wavelength');
            ylabel(app.PreprocessedDataAxes, 'Intensity');
        end

        function exportData(app)
            if isempty(app.PreprocessedMatrix)
                uialert(app.UIFigure, 'No preprocessed data to export', 'Error');
                return;
            end
            assignin('base', 'preprocessedData', app.PreprocessedMatrix);
            uialert(app.UIFigure, 'Data exported to workspace', 'Success');
        end

    end

    methods (Access = private)

        function startupFcn(app)
            app.DataMatrix = [];
            app.PreprocessedMatrix = [];
        end

    end

    methods (Access = private)

        % Button pushed function: LoadDataButton
        function LoadDataButtonPushed(app, event)
            loadData(app);
        end

        % Button pushed function: ApplyBinningButton
        function ApplyBinningButtonPushed(app, event)
            binningPreprocessing(app);
        end

        % Button pushed function: ApplyAsLSButton
        function ApplyAsLSButtonPushed(app, event)
            baselineCorrection(app);
        end

        % Button pushed function: ExportDataButton
        function ExportDataButtonPushed(app, event)
            exportData(app);
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'MATLAB App';

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.UIFigure, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);
            app.LoadDataButton.Position = [50 540 100 22];
            app.LoadDataButton.Text = 'Load Data';

            % Create BinSizeEditFieldLabel
            app.BinSizeEditFieldLabel = uilabel(app.UIFigure);
            app.BinSizeEditFieldLabel.HorizontalAlignment = 'right';
            app.BinSizeEditFieldLabel.Position = [200 540 50 22];
            app.BinSizeEditFieldLabel.Text = 'Bin Size';

            % Create BinSizeEditField
            app.BinSizeEditField = uieditfield(app.UIFigure, 'numeric');
            app.BinSizeEditField.Position = [260 540 100 22];
            app.BinSizeEditField.Value = 1;

            % Create ApplyBinningButton
            app.ApplyBinningButton = uibutton(app.UIFigure, 'push');
            app.ApplyBinningButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyBinningButtonPushed, true);
            app.ApplyBinningButton.Position = [380 540 100 22];
            app.ApplyBinningButton.Text = 'Apply Binning';

            % Create LambdaEditFieldLabel
            app.LambdaEditFieldLabel = uilabel(app.UIFigure);
            app.LambdaEditFieldLabel.HorizontalAlignment = 'right';
            app.LambdaEditFieldLabel.Position = [200 500 50 22];
            app.LambdaEditFieldLabel.Text = 'Lambda';

            % Create LambdaEditField
            app.LambdaEditField = uieditfield(app.UIFigure, 'numeric');
            app.LambdaEditField.Position = [260 500 100 22];
            app.LambdaEditField.Value = 1e5;

            % Create PEditFieldLabel
            app.PEditFieldLabel = uilabel(app.UIFigure);
            app.PEditFieldLabel.HorizontalAlignment = 'right';
            app.PEditFieldLabel.Position = [200 460 50 22];
            app.PEditFieldLabel.Text = 'P';

            % Create PEditField
            app.PEditField = uieditfield(app.UIFigure, 'numeric');
            app.PEditField.Position = [260 460 100 22];
            app.PEditField.Value = 0.001;

            % Create ApplyAsLSButton
            app.ApplyAsLSButton = uibutton(app.UIFigure, 'push');
            app.ApplyAsLSButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyAsLSButtonPushed, true);
            app.ApplyAsLSButton.Position = [380 480 100 22];
            app.ApplyAsLSButton.Text = 'Apply AsLS';

            % Create ExportDataButton
            app.ExportDataButton = uibutton(app.UIFigure, 'push');
            app.ExportDataButton.ButtonPushedFcn = createCallbackFcn(app, @ExportDataButtonPushed, true);
            app.ExportDataButton.Position = [50 500 100 22];
            app.ExportDataButton.Text = 'Export Data';

            % Create RawDataAxes
            app.RawDataAxes = uiaxes(app.UIFigure);
            title(app.RawDataAxes, 'Raw Data')
            xlabel(app.RawDataAxes, 'Wavelength')
            ylabel(app.RawDataAxes, 'Intensity')
            app.RawDataAxes.Position = [50 50 340 400];

            % Create PreprocessedDataAxes
            app.PreprocessedDataAxes = uiaxes(app.UIFigure);
            title(app.PreprocessedDataAxes, 'Preprocessed Data')
            xlabel(app.PreprocessedDataAxes, 'Binned Wavelength')
            ylabel(app.PreprocessedDataAxes, 'Intensity')
            app.PreprocessedDataAxes.Position = [410 50 340 400];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = SpectroscopyPreprocessingApp

            % Create UIFigure and components
            createComponents(app)

            % Execute the startup function
            startupFcn(app)
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end

function corrected = asls(y, lambda, p)
    L = length(y);
    D = diff(speye(L), 2);
    H = lambda * (D' * D);
    w = ones(L, 1);
    for i = 1:10
        W = spdiags(w, 0, L, L);
        C = chol(W + H);
        z = C \ (C' \ (w .* y'));
        w = p * (y' > z) + (1 - p) * (y' < z);
    end
    corrected = y - z';
end
