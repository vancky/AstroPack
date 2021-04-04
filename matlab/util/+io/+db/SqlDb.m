% FITS Database Class
%--------------------------------------------------------------------------


classdef SqlDb < Component
    % Properties
    properties (SetAccess = public)
        %config          % Configuration 
        %log             % Log file
    end
    
    %-------------------------------------------------------- 
    methods
        % Constructor    
        function Obj = SqlDb(FileName)
            Obj.FileName = FileName;
        end
    end
    
    
    methods
        
        
        %
        function Result = Open(Obj, FileName)
            Obj.FileName = FileName;
            Result = true;
        end
        
        
        % Read         
        function Data = read(Obj)
            Data = fitsread(Obj.FileName);       
        end
        
        
        function Header = readHeader(Obj, Path)
        end
        
            
    end

    
    methods(Static)
    end
    
    
    %----------------------------------------------------------------------
    % Unit test
    methods(Static)
        function Result = unitTest()
            fprintf("Started\n");
            
            addpath("D:\Ultrasat\AstroPack.git\matlab\external");

            % Test: Read image 
            FileName = "D:\\Ultrasat\\AstroPack.git\\data\\test_images\\local\\image1.fits";
            db = FitsDb(FileName);
            data = db.read(FileName);
            
            % Test: Read more images (HDU)
            disp(size(data));
            
            % Test: Create database and tables
            
            % Test: Write data to tables
            
            % Test: Query tables         
            
 
            Result = true;
        end
    end    
        
    
end





function msgLog(varargin)
    %fprintf('fits: ');
    fprintf(varargin{:});
    fprintf('\n');
end



