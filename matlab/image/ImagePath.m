
classdef ImagePath < handle
    properties
        FullName char       = '';
        Path char           = '';
        FileName char       = '';
        
    end
    
    properties
        % Each property is mapped to field in common_image_path table


        % Instrument
        Telescope       = '';       % (ProjName) - source instrument (last_xx/ultrasat) - LAST.<#>.<#>.<#> or ???
        Node            = '';
        Mount           = '';
        Camera          = '';
        JD double       = 0;        % (UTC start of exposure)
        Timezone        = 0;        % Bias in hours, to generate folder name

        % Filter and Field
        Filter          = '';
        FieldId         = '';
        CropId          = '';

        % Image
        ImageType       = '';       % sci, bias, dark, domeflat, twflat, skyflat, fringe
        ImageLevel      = '';       % log, raw, proc, stack, coadd, ref.
        ImageSubLevel   = '';       % Sub level
        ImageProduct    = '';       % Product: im, back, var, imflag, exp, Nim, psf, cat, spec.
        ImageVer        = '';       % Version (for multiple processing)
        FileType        = '';       % fits / hdf5 / fits.gz

        % Debug? or have it?
        BasePath        = '/data/store';    % 
        FullPath        = '';       %
        
        
%         ProjName char       = 'none';
%         Date                = NaN;
%         Filter char         = 'clear';
%         FieldID             = '';
%         FormatFieldID char  = '%06d';
%         Type char           = 'sci';
%         Level char          = 'raw';
%         SubLevel char       = '';
%         Product char        = 'im';
%         Version             = 1;
%         FormatVersion       = '%03d';
%         FileType            = 'fits';
%         TimeZone            = 2;
%         RefVersion          = 1;
%         FormatRefVersion    = '%03d';
%         SubDir              = '';
%         DataDir             = 'data';
%         Base                = '/home/last';
    end
    
    
    methods % Constructor
       
        function Obj = ImagePath(varargin)
            % Base class constructor
            % Package: @Base           
            
            % readFromHeader...
            
            if iswindows()
                Obj.BasePath = 'C:\\Data\\Store';
            end
        end
    end
    
    
    methods
        function Result = readFromHeader(Obj, Header)
            arguments
                Obj
                Header AstroHeader
            end
            
            Obj.Telescope       = Header.Key.TEL;
            Obj.Node            = Header.Key.NODE;
            Obj.Mount           = Header.Key.MOUNT;
            Obj.Camera          = Header.Key.CAMERA;
            Obj.JD              = Header.Key.JD; 
            Obj.Timezone        = Header.Key.TIMEZONE;
            Obj.Filter          = Header.Key.FILTER;
            Obj.FieldId         = Header.Key.FIELDID;
            Obj.CropId          = Header.Key.CROPID;
            Obj.ImageType       = Header.Key.IMTYPE;
            Obj.ImageLevel      = Header.Key.IMLEVEL;
            Obj.ImageSubLevel   = Header.Key.IMSLEVEL;
            Obj.ImageProduct    = Header.Key.IMPROD;
            Obj.ImageVer        = Header.Key.IMVER;
            Obj.FileType        = Header.Key.FILETYPE;

            Result = true;
        end
        
        
        function Result = writeToHeader(Obj, Header)
            arguments
                Obj
                Header AstroHeader
            end
            
            Header.Key.TEL      = Obj.Telescope;
            Header.Key.NODE     = Obj.Node;
            Header.Key.MOUNT    = Obj.Mount;
            Header.Key.CAMERA   = Obj.Camera;
            Header.Key.JD       = Obj.JD;
            Header.Key.TIMEZONE = Obj.Timezone;
            Header.Key.FILTER   = Obj.Filter;
            Header.Key.FIELDID  = Obj.FieldId;
            Header.Key.CROPID   = Obj.CropId;
            Header.Key.IMTYPE   = Obj.ImageType;
            Header.Key.IMLEVEL  = Obj.ImageLevel;
            Header.Key.IMSLEVEL = Obj.ImageSubLevel;
            Header.Key.IMPROD   = Obj.ImageProduct;
            Header.Key.IMVER    = Obj.ImageVer;
            Header.Key.FILETYPE = Obj.FileType;
            
            Result = true;
        end        
        
        
        function Result = readFromDb(Obj, Query)
            arguments
                Obj
                Query io.db.DbQuery
            end            
            
            st = Query.getRecord();
            Obj.Telescope       = st.tel;
            Obj.Node            = st.node;
            Obj.Mount           = st.mount;
            Obj.Camera          = st.camera;
            Obj.JD              = st.jd;
            Obj.Timezone        = st.timezone;
            Obj.Filter          = st.filter;
            Obj.FieldId         = st.field_id;
            Obj.CropId          = st.crop_id;
            Obj.ImageType       = st.imtype;
            Obj.ImageLevel      = st.imlevel;
            Obj.ImageSubLevel   = st.imslevel;
            Obj.ImageProduct    = st.improd;
            Obj.ImageVer        = st.imver;
            Obj.FileType        = st.filetype;
            Result = true;
        end
        
        
        function Result = writeToDb(Obj, Query)
            arguments
                Obj
                Query io.db.DbQuery
            end
            
            st = struct;
            st.tel      = Obj.Telescope;
            st.node     = Obj.Node;
            st.mount    = Obj.Mount;
            st.camera   = Obj.Camera;
            st.jd       = Obj.JD;
            st.timezone = Obj.Timezone;
            st.filter   = Obj.Filter;
            st.field_id = Obj.FieldId;
            st.crop_id  = Obj.CropId;
            st.imtype   = Obj.ImageType;
            st.imlevel  = Obj.ImageLevel;
            st.imslevel = Obj.ImageSubLevel;
            st.improd   = Obj.ImageProduct;
            st.imver    = Obj.ImageVer;
            st.filetype = Obj.FileType;

            Query.insertRecord(Query.TableName, st);
            Result = true;
        end        
    end
        
    % setters and getters
    methods       

    end
    
    
    methods
        
        % <ProjName>.<TelescopeID>_YYYYMMDD.HHMMSS.FFF_<filter>_<FieldID>_<type>_<level>.<sub level>_<Product>_<version>.<FileType>
               
        function [FileName, Path] = makeFileName(Obj)
            
            FileName = sprintf('%s%s%s', 
            
            Obj.Telescope
            Obj.Node
            Obj.Mount
            Obj.Camera
            Obj.JD
            Obj.Timezone
            Obj.Filter
            Obj.FieldId
            Obj.CropId
            Obj.ImageType
            Obj.ImageLevel
            Obj.ImageSubLevel
            Obj.ImageProduct
            Obj.ImageVer
            Obj.FileType
            
            
            Obj.FileName    = FileName;
            Obj.FullName    = sprintf('%s%s%s',Path,filesep,FileName);
            Obj.Path        = Path;
            
        end
 
    end
    
    
    methods(Static)    
        function Result = createFromDbQuery(Obj, Query)
            % Create ImagePath
                
        end
    end
    
    
    %----------------------------------------------------------------------
    % Unit test
    methods(Static)
        function Result = unitTest()
            io.msgStyle(LogLevel.Test, '@start', 'ImagePath test started\n');
    
            %p = ImagePath;
            %fn = p.FullName;
            
            % Done
            io.msgStyle(LogLevel.Test, '@passed', 'ImagePath test passed')
            Result = true;
        end
    end    
    
end
