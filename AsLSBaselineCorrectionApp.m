classdef AsLSBaselineCorrectionApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        LoadDataButton             matlab.ui.control.Button
        ApplyAsLSButton            matlab.ui.control.Button
        ExportDataButton           matlab.ui.control.Button
        LambdaEditFieldLabel       matlab.ui.control.Label
        LambdaEditField            matlab.ui.control.NumericEditField
        PEditFieldLabel            matlab.ui.control.Label
        PEditField                 matlab.ui.control.NumericEditField
        RawDataAxes                matlab.ui.control.UIAxes
        CorrectedDataAxes          matlab.ui.control.UIAxes
    end

    properties (Access = private)
        DataMatrix   double         % Input data matrix
        CorrectedData double        % Corrected data matrix
    end
    
    methods (Access = private)
        
        function data = applyAsLS(app, y, lambda, p)
            % Function to apply AsLS baseline correction
            L = length(y);
            D = diff(speye(L), 2);
            w = ones(L, 1);
            for i = 1:10
                W = spdiags(w, 0, L, L);
                Z = W + lambda * D' * D;
                z = Z \ (w .* y);
                w = p * (y > z) + (1 - p) * (y < z);
            end
            data = y - z;
        end
        
        function updatePlots(app)
            % Update the plots with raw and corrected data
            if isempty(app.DataMatrix)
                return;
            end
            plot(app.RawDataAxes, app.DataMatrix');
            title(app.RawDataAxes, 'Raw Data');
            xlabel(app.RawDataAxes, 'Wavelength');
            ylabel(app.RawDataAxes, 'Intensity');
            
            if ~isempty(app.CorrectedData)
                plot(app.CorrectedDataAxes, app.CorrectedData');
                title(app.CorrectedDataAxes, 'AsLS Corrected Data');
                xlabel(app.CorrectedDataAxes, 'Wavelength');
                ylabel(app.CorrectedDataAxes, 'Intensity');
            end
        end
        
        function loadData(app)
            % Load data from file
            [file, path] = uigetfile('*.mat');
            if isequal(file, 0)
                return;
            end
            dataStruct = load(fullfile(path, file));
            dataFields = fieldnames(dataStruct);
            app.DataMatrix = dataStruct.(dataFields{1});
            app.CorrectedData = [];
            app.updatePlots();
        end
        
        function applyCorrection(app)
            % Apply AsLS baseline correction to data
            lambda = app.LambdaEditField.Value;
            p = app.PEditField.Value;
            [numSamples, numWavelengths] = size(app.DataMatrix);
            app.CorrectedData = zeros(numSamples, numWavelengths);
            for i = 1:numSamples
                app.CorrectedData(i, :) = app.applyAsLS(app.DataMatrix(i, :)', lambda, p);
            end
            app.updatePlots();
        end
        
        function exportData(app)
            % Export corrected data to the workspace
            if ~isempty(app.CorrectedData)
                assignin('base', 'CorrectedData', app.CorrectedData);
                uialert(app.UIFigure, 'Corrected data has been exported to the workspace as ''CorrectedData''.', 'Export Successful');
            else
                uialert(app.UIFigure, 'No corrected data to export.', 'Export Error');
            end
        end
        
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadDataButton
        function LoadDataButtonPushed(app, event)
            app.loadData();
        end

        % Button pushed function: ApplyAsLSButton
        function ApplyAsLSButtonPushed(app, event)
            app.applyCorrection();
        end
        
        % Button pushed function: ExportDataButton
        function ExportDataButtonPushed(app, event)
            app.exportData();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UI components and set their properties
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'AsLS Baseline Correction';

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.UIFigure, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);
            app.LoadDataButton.Position = [20 550 100 22];
            app.LoadDataButton.Text = 'Load Data';

            % Create ApplyAsLSButton
            app.ApplyAsLSButton = uibutton(app.UIFigure, 'push');
            app.ApplyAsLSButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyAsLSButtonPushed, true);
            app.ApplyAsLSButton.Position = [140 550 100 22];
            app.ApplyAsLSButton.Text = 'Apply AsLS';

            % Create ExportDataButton
            app.ExportDataButton = uibutton(app.UIFigure, 'push');
            app.ExportDataButton.ButtonPushedFcn = createCallbackFcn(app, @ExportDataButtonPushed, true);
            app.ExportDataButton.Position = [260 550 100 22];
            app.ExportDataButton.Text = 'Export Data';

            % Create LambdaEditFieldLabel
            app.LambdaEditFieldLabel = uilabel(app.UIFigure);
            app.LambdaEditFieldLabel.HorizontalAlignment = 'right';
            app.LambdaEditFieldLabel.Position = [380 550 50 22];
            app.LambdaEditFieldLabel.Text = 'Lambda';

            % Create LambdaEditField
            app.LambdaEditField = uieditfield(app.UIFigure, 'numeric');
            app.LambdaEditField.Position = [440 550 100 22];
            app.LambdaEditField.Value = 1e6;

            % Create PEditFieldLabel
            app.PEditFieldLabel = uilabel(app.UIFigure);
            app.PEditFieldLabel.HorizontalAlignment = 'right';
            app.PEditFieldLabel.Position = [560 550 25 22];
            app.PEditFieldLabel.Text = 'p';

            % Create PEditField
            app.PEditField = uieditfield(app.UIFigure, 'numeric');
            app.PEditField.Position = [600 550 100 22];
            app.PEditField.Value = 0.001;

            % Create RawDataAxes
            app.RawDataAxes = uiaxes(app.UIFigure);
            title(app.RawDataAxes, 'Raw Data');
            xlabel(app.RawDataAxes, 'Wavelength');
            ylabel(app.RawDataAxes, 'Intensity');
            app.RawDataAxes.Position = [20 300 360 200];

            % Create CorrectedDataAxes
            app.CorrectedDataAxes = uiaxes(app.UIFigure);
            title(app.CorrectedDataAxes, 'AsLS Corrected Data');
            xlabel(app.CorrectedDataAxes, 'Wavelength');
            ylabel(app.CorrectedDataAxes, 'Intensity');
            app.CorrectedDataAxes.Position = [400 300 360 200];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = AsLSBaselineCorrectionApp

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
