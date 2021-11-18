% Top-level configuration
%
% Load multiple configuration files as properties
%
% Load all YML files in folder
% Access each file as property of the Configuration object.
%
% Note: Since Configuration.getSingleton() uses persistant object,
%       in order to load fresh configuration you need to do 'clear all'
%--------------------------------------------------------------------------

classdef Configuration < handle
    
    % Properties
    properties (SetAccess = public)
        ConfigName              % Optional name for the entire configuration
        Path                    % Path of configuration files
        External                % Path to external packages
        Data struct = struct()  % Initialize empty struct, all YML files are added here in tree structure
    end
    
    %-------------------------------------------------------- 
    methods % Constructor            
        function Obj = Configuration()
            
            % Get full path and name of the file in which the call occurs, 
            % not including the filename extension
            MyFileName = mfilename('fullpath');       
            [MyPath, ~, ~] = fileparts(MyFileName);            
            
            % Set path to configuration files
            % @FFU: overide with env???
            Obj.Path = fullfile(MyPath, '..', '..', 'config');
            
            % Set path to yaml external package
            % Replace it with env? move to startup.m?
            Obj.External = fullfile(MyPath, '..', 'external');
            
            % commented out by Enrico. Obtrusive. If there is really a
            %  value in these messages, make them conditioned to when I'm
            %  not using the class
            % fprintf('Configuration Path: %s\n', Obj.Path);
            % fprintf('Configuration External: %s\n', Obj.External);
            % fprintf('Master Configuration files are located in AstroPack/config\n');            
            
            % Validate                      
            assert(~isempty(Obj.Path));
            assert(~isempty(Obj.External));
            assert(isfolder(Obj.Path));
            assert(isfolder(Obj.External));            
            
            addpath(Obj.External);            
        end
    end

    
    methods % Main functions
         
        function loadConfig(Obj)
            % Load entire Configuration: all files in folder
            
            % Load default folder            
            Obj.loadFolder(Obj.Path);
            
            % Load local files
            Obj.loadFolder(fullfile(Obj.Path, 'local'));
        end
        
        
        function Result = loadFile(Obj, FileName, Args)
            % Load specified file to property            
            
            arguments
                Obj
                FileName
                
                % True to create new property in Obj.Data with the file
                % name, otherwise YML is loaded directly into Data
                Args.Field logical = true;
            end
        
            Result = false;
            try
                [~, name, ~] = fileparts(FileName);
                PropName = name;
                if isfield(Obj.Data, PropName)
                    io.msgLog(LogLevel.Warning, 'Property already exist: Data.%s', PropName);
                else
                    io.msgLog(LogLevel.Info, 'Adding property: %s', PropName);                    
                end
                
                % Yml is used used below by eval()
                try
                    Yml = Configuration.loadYaml(FileName); %#ok<NASGU>
                    Result = true;
                catch
                    io.msgLog(LogLevel.Error, 'Configuration.loadYaml failed: %s', FileName);                    
                    Yml = struct; %#ok<NASGU>
                end
                
                % When name contains dots, create tree of structs (i.e. 'x.y.z')
                if Args.Field
                    s = sprintf('Obj.Data.%s=Yml;', name);
                else
                    s = sprintf('Obj.Data=Yml;');
                end
                eval(s);                
            catch
                io.msgStyle(LogLevel.Error, '@error', 'loadFile: Exception: %s', FileName);
            end
        end
        
        
        function loadFolder(Obj, Path)
            % Load specified folder to properties

            %@Todo: fix
            %Obj.Path = Path;
            %Obj.ConfigName = 'Config';
            io.msgLog(LogLevel.Info, 'loadFolder: %s', Obj.Path);
            
            List = dir(fullfile(Path, '*.yml'));
            for i = 1:length(List)
                if ~List(i).isdir
                    FileName = fullfile(List(i).folder, List(i).name);
                    Obj.loadFile(FileName);
                end
            end
        end
       
     
        function reloadFile(Obj, YamlStruct)
            % Reload specified configuration file            
            Configuration.reload(Obj.(YamlStruct));
        end        
       
     
        function reloadFolder(Obj)
            % Reload all configuration files from folder            
            loadFolder(Obj, Obj.Path);
        end        
        
        
        function Result = expandFolder(Obj, Path)
            % Expand Path with macros from Configuration.System.EnvFolders
            if isfield(Obj.Data, 'System') && isfield(Obj.Data.System, 'EnvFolders')
                Result = Configuration.unmacro(Path, Obj.Data.System.EnvFolders);
            else
                Result = Path;
            end
        end
        
    end

    %----------------------------------------------------------------------   
    methods(Static) % Static functions
                
        function Result = init(varargin)
            % Return singleton Configuration object
            persistent Conf
            
            % Clear configuration
            if numel(varargin) > 0
                Conf = [];
            end
            
            if isempty(Conf)
                Conf = Configuration;
            end
            Result = Conf;
        end
        
        
        function Result = getSingleton()
            % Return singleton Configuration object
            Conf = Configuration.init();
            if isempty(Conf.Data) || numel(fieldnames(Conf.Data)) == 0
                Conf.loadConfig();
            end
            Result = Conf;
        end
        
                 
        function YamlStruct = loadYaml(FileName)
            % Read YAML file to struct, add FileName field
            io.msgLog(LogLevel.Info, 'loadYaml: Loading file: %s', FileName);          
            try
                if ~isfile(FileName)
                    io.msgLog(LogLevel.Error, 'loadYaml: File not found: %s', FileName);
                end
                YamlStruct = yaml.ReadYaml(string(FileName).char);
                YamlStruct.FileName = FileName;
            catch
                io.msgStyle(LogLevel.Error, '@error', 'loadYaml: Exception loading file: %s', FileName);
            end
        end
     
        
        function NewYamlStruct = reloadYaml(YamlStruct)
            % Reload configurastion file, 'FileName' field must exist
            if isfield(YamlStruct, 'FileName')
                NewYamlStruct = Configuration.loadYaml(YamlStruct.FileName);
            else
                msgLog('loadYaml: reloadYaml: no FileName property');
                NewYamlStruct = YamlStruct;
            end
        end       
    end
    
    
    methods(Static) % Helper functions
   
        function Result = unmacro(Str, MacrosStruct)
            % Replace macros in string with values from struct
            % Str="$Root/abc", MacrosStruct.Root="xyz" -> "xyz/abc"
            % conf.unmacro(conf.Yaml.DarkImage.InputFolder, conf.Yaml.EnvFolders)
            
            FieldNames = fieldnames(MacrosStruct);
            for i = 1:numel(FieldNames)
                Var = FieldNames{i};
                Macro = "$" + Var;
                Value = MacrosStruct.(Var);
                if contains(Str, Macro)
                    NewStr = strrep(Str, Macro, Value);
                    Str = NewStr;
                end                    
            end
            Result = Str;
        end
              

        function [Min, Max] = getRange(Cell)
            % Get minimum and maximum values from cell array
            % Example: [min, max] = conf.getRange(conf.Yaml.DarkImage.TemperatureRange)            
            Min = Cell{1};
            Max = Cell{2};
        end
               
        
        function Len = listLen(List)
            % Return list length
            [~, Len] = size(List);
        end
        
        
        function Value = listItem(List, Index)
            Value = List;
        end
        
    end
    
    %----------------------------------------------------------------------   
    methods(Static) % Unit test       
            
        function Result = unitTest()
            io.msgLog(LogLevel.Test, 'Configuration test started');
            
            % Clear java to avoid failure of yaml.ReadYaml()
            clear java;
            
            % Initialize and get a singletone persistant object
            Conf = Configuration.init();
            assert(~isempty(Conf.Path));
            assert(~isempty(Conf.External));
            assert(isfolder(Conf.Path));
            assert(isfolder(Conf.External));            
            
            fprintf('Conf.Path: %s\n', Conf.Path);
            fprintf('Conf.External: %s\n', Conf.External);

            ConfigPath = Conf.Path;
            ConfigFileName = fullfile(ConfigPath, 'UnitTest.yml');
            
            % Private configuration file, load directly to Data
            PrivateConf = Configuration;
            % Field = false will load only the ConfigFileName into the Data
            % without the full struct
            PrivateConf.loadFile(ConfigFileName, 'Field', false);
            assert(~isfield(PrivateConf.Data, 'UnitTest'));
            assert(isfield(PrivateConf.Data, 'Key1'));            
            
            % Private configuration file, load to Data.UnitTest
            PrivateConf2 = Configuration;
            PrivateConf2.loadFile(ConfigFileName);          
            assert(isfield(PrivateConf2.Data, 'UnitTest'));
            assert(isfield(PrivateConf2.Data.UnitTest, 'Key1'));
            
            % Test low level loading of Yaml struct
            io.msgLog(LogLevel.Test, 'Testing low level functions');
            yml = Configuration.loadYaml(ConfigFileName);
            uTest = yml;
            io.msgLog(LogLevel.Test, 'Key1: %s', uTest.Key1);
            io.msgLog(LogLevel.Test, 'Key2: %s', uTest.Key2);
            io.msgLog(LogLevel.Test, 'Key: %s', uTest.Key0x2D3);
            io.msgLog(LogLevel.Test, 'Key: %s', uTest.x0x2DKeyMinus);
            yml = Configuration.reloadYaml(yml);
            uTest = yml;
            io.msgLog(LogLevel.Test, 'Key1: %s', uTest.Key1);                  
            
            % Test Configuration class
            io. msgLog(LogLevel.Test, 'Testing Configuration object');
            Conf.loadFile(ConfigFileName);
            
            confUnitTest = Conf.Data.UnitTest;
            
            %
            io.msgLog(LogLevel.Test, 'FileName: %s', confUnitTest.FileName);
            disp(Conf.Data.UnitTest);         
            
            %
            io.msgLog(LogLevel.Test, 'Key1: %s', confUnitTest.Key1);
            io.msgLog(LogLevel.Test, 'Key2: %s', confUnitTest.Key2);
            io.msgLog(LogLevel.Test, 'Key: %s', confUnitTest.Key0x2D3);
            io.msgLog(LogLevel.Test, 'Key: %s', confUnitTest.x0x2DKeyMinus);
            
            %disp(conf.listLen(conf.UnitTest.NonUniqueKeys));
                    
            % Load all config files in folder
            io.msgLog(LogLevel.Test, 'Testing folder');
            Conf.loadFolder(ConfigPath);
            disp(Conf.Data.System.EnvFolders);
            
            io.msgLog(LogLevel.Test, 'Testing utility functions');
            io.msgLog(LogLevel.Test, 'unmacro: %s', Configuration.unmacro("$ROOT/abc", Conf.Data.System.EnvFolders));
            
            io.msgLog(LogLevel.Test, 'expandFolder: %s', Conf.expandFolder("$ROOT/abc"));
            
            % Done
            io.msgLog(LogLevel.Test, 'Configuration test passed');
            Result = true;
        end
    end
        
end
