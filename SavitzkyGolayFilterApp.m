classdef SavitzkyGolayFilterApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        LoadDataButton          matlab.ui.control.Button
        ApplyFilterButton       matlab.ui.control.Button
        ExportDataButton        matlab.ui.control.Button
        RawDataPlot             matlab.ui.control.UIAxes
        SmoothedDataPlot        matlab.ui.control.UIAxes
        DerivativeDataPlot      matlab.ui.control.UIAxes
        WindowSizeFieldLabel    matlab.ui.control.Label
        WindowSizeField         matlab.ui.control.NumericEditField
        PolyOrderFieldLabel     matlab.ui.control.Label
        PolyOrderField          matlab.ui.control.NumericEditField
        DerivativeOrderFieldLabel matlab.ui.control.Label
        DerivativeOrderField    matlab.ui.control.NumericEditField
        Data                    double
        SmoothedData            double
        DerivativeData          double
    end

    methods (Access = private)

        % Button pushed function: LoadDataButton
        function LoadDataButtonPushed(app, event)
            [file, path] = uigetfile('*.mat', 'Select the Spectroscopic Data File');
            if isequal(file, 0)
                return;
            else
                data = load(fullfile(path, file));
                fields = fieldnames(data);
                app.Data = data.(fields{1});
                plot(app.RawDataPlot, app.Data');
                title(app.RawDataPlot, 'Raw Data');
                xlabel(app.RawDataPlot, 'Wavelength');
                ylabel(app.RawDataPlot, 'Intensity');
            end
        end

        % Button pushed function: ApplyFilterButton
        function ApplyFilterButtonPushed(app, event)
            windowSize = app.WindowSizeField.Value;
            polyOrder = app.PolyOrderField.Value;
            derivOrder = app.DerivativeOrderField.Value;

            if isempty(app.Data)
                uialert(app.UIFigure, 'No data loaded. Please load the data first.', 'Data Error');
                return;
            end

            if mod(windowSize, 2) == 0
                uialert(app.UIFigure, 'Window size must be an odd number.', 'Parameter Error');
                return;
            end

            if polyOrder >= windowSize
                uialert(app.UIFigure, 'Polynomial order must be less than the window size.', 'Parameter Error');
                return;
            end

            if derivOrder < 0 || derivOrder > 2
                uialert(app.UIFigure, 'Derivative order must be 0, 1, or 2.', 'Parameter Error');
                return;
            end

            [rows, cols] = size(app.Data);
            app.SmoothedData = zeros(size(app.Data));
            app.DerivativeData = zeros(size(app.Data));

            % Get the Savitzky-Golay filter coefficients
            [b, g] = sgolay(polyOrder, windowSize);
            halfWin = (windowSize - 1) / 2;

            % Apply the filter to each row of data
            for i = 1:rows
                % Pad data with reflected values at the boundaries
                paddedData = padarray(app.Data(i, :), [0, halfWin], 'symmetric');

                % Apply smoothing
                smoothed = conv(paddedData, factorial(0) * g(:, 1)', 'same');
                app.SmoothedData(i, :) = smoothed(halfWin+1:end-halfWin);

                % Apply derivative
                derivative = conv(paddedData, factorial(derivOrder) * g(:, derivOrder + 1)', 'same');
                app.DerivativeData(i, :) = derivative(halfWin+1:end-halfWin);
            end

            plot(app.SmoothedDataPlot, app.SmoothedData');
            title(app.SmoothedDataPlot, 'Smoothed Data');
            xlabel(app.SmoothedDataPlot, 'Wavelength');
            ylabel(app.SmoothedDataPlot, 'Intensity');

            plot(app.DerivativeDataPlot, app.DerivativeData');
            title(app.DerivativeDataPlot, ['Derivative Order ', num2str(derivOrder)]);
            xlabel(app.DerivativeDataPlot, 'Wavelength');
            ylabel(app.DerivativeDataPlot, 'Intensity');
        end

        % Button pushed function: ExportDataButton
        function ExportDataButtonPushed(app, event)
            if isempty(app.SmoothedData) || isempty(app.DerivativeData)
                uialert(app.UIFigure, 'No data to export. Please apply the filter first.', 'Export Error');
                return;
            end
            assignin('base', 'SmoothedData', app.SmoothedData);
            assignin('base', 'DerivativeData', app.DerivativeData);
            uialert(app.UIFigure, 'Filtered data has been exported to the MATLAB workspace.', 'Export Success');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 600];
            app.UIFigure.Name = 'Savitzky-Golay Filter App';

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.UIFigure, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);
            app.LoadDataButton.Position = [50 550 100 30];
            app.LoadDataButton.Text = 'Load Data';

            % Create ApplyFilterButton
            app.ApplyFilterButton = uibutton(app.UIFigure, 'push');
            app.ApplyFilterButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyFilterButtonPushed, true);
            app.ApplyFilterButton.Position = [170 550 100 30];
            app.ApplyFilterButton.Text = 'Apply Filter';

            % Create ExportDataButton
            app.ExportDataButton = uibutton(app.UIFigure, 'push');
            app.ExportDataButton.ButtonPushedFcn = createCallbackFcn(app, @ExportDataButtonPushed, true);
            app.ExportDataButton.Position = [290 550 100 30];
            app.ExportDataButton.Text = 'Export Data';

            % Create RawDataPlot
            app.RawDataPlot = uiaxes(app.UIFigure);
            app.RawDataPlot.Position = [50 300 350 200];
            title(app.RawDataPlot, 'Raw Data');
            xlabel(app.RawDataPlot, 'Wavelength');
            ylabel(app.RawDataPlot, 'Intensity');

            % Create SmoothedDataPlot
            app.SmoothedDataPlot = uiaxes(app.UIFigure);
            app.SmoothedDataPlot.Position = [420 300 350 200];
            title(app.SmoothedDataPlot, 'Smoothed Data');
            xlabel(app.SmoothedDataPlot, 'Wavelength');
            ylabel(app.SmoothedDataPlot, 'Intensity');

            % Create DerivativeDataPlot
            app.DerivativeDataPlot = uiaxes(app.UIFigure);
            app.DerivativeDataPlot.Position = [790 300 350 200];
            title(app.DerivativeDataPlot, 'Derivative Data');
            xlabel(app.DerivativeDataPlot, 'Wavelength');
            ylabel(app.DerivativeDataPlot, 'Intensity');

            % Create WindowSizeFieldLabel
            app.WindowSizeFieldLabel = uilabel(app.UIFigure);
            app.WindowSizeFieldLabel.HorizontalAlignment = 'right';
            app.WindowSizeFieldLabel.Position = [50 500 70 22];
            app.WindowSizeFieldLabel.Text = 'Window Size';

            % Create WindowSizeField
            app.WindowSizeField = uieditfield(app.UIFigure, 'numeric');
            app.WindowSizeField.Position = [130 500 100 22];
            app.WindowSizeField.Value = 5;

            % Create PolyOrderFieldLabel
            app.PolyOrderFieldLabel = uilabel(app.UIFigure);
            app.PolyOrderFieldLabel.HorizontalAlignment = 'right';
            app.PolyOrderFieldLabel.Position = [250 500 100 22];
            app.PolyOrderFieldLabel.Text = 'Polynomial Order';

            % Create PolyOrderField
            app.PolyOrderField = uieditfield(app.UIFigure, 'numeric');
            app.PolyOrderField.Position = [360 500 100 22];
            app.PolyOrderField.Value = 2;

            % Create DerivativeOrderFieldLabel
            app.DerivativeOrderFieldLabel = uilabel(app.UIFigure);
            app.DerivativeOrderFieldLabel.HorizontalAlignment = 'right';
            app.DerivativeOrderFieldLabel.Position = [480 500 100 22];
            app.DerivativeOrderFieldLabel.Text = 'Derivative Order';

            % Create DerivativeOrderField
            app.DerivativeOrderField = uieditfield(app.UIFigure, 'numeric');
            app.DerivativeOrderField.Position = [590 500 100 22];
            app.DerivativeOrderField.Value = 0;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = SavitzkyGolayFilterApp

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
