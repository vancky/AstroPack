% BaseImage handle class - all images inherits from this class
% Package: @BaseImage
% Description: 
% Tested : Matlab R2018a
% Author : Eran O. Ofek (Mar 2021)
% Dependencies: @convert, @celestial
% Example : 
% Reliable: 2
%--------------------------------------------------------------------------

classdef AstroImage < Component
    
    properties (Hidden, SetAccess = public)

        % Access image data directly
        Image
        Back
        
        % Images
        BImage BaseImage
        BBack BaseImage
    end
    
    
    %-------------------
    %--- Constructor ---
    %-------------------
    methods
       
        function Obj = AstroImage
            
            
        end

    end
    
 
    
    % Setters/Getters
    methods
        function Obj = set.Image(Obj, Data)
            Obj.BImage.setData(Data); %#ok<MCSUP>
        end
        
        function Data = get.Image(Obj)
            Data = Obj.BImage.getData();
        end        
    end
    
    % static methods
    methods (Static)
       
    end
    
    % 
    
    % setters/getters
    methods
        
    end
    
    % static methods
    methods (Static)

        function Result = unitTest()
            Astro = AstroImage;
            
        end
    end
    
    

end

            
