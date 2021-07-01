% Tran2D class: An astrometric transformation class
% Description: A 2D transformation object designed for astrometric
%              transformations of 2D images.
%              It supports linear transformations of the form:
%              Xi = c1*FunX{1}(x,y,add_par) + c2*Fun{2}(...) + ...
%              Yi = ...
%              FunX are user defined functionals
%              x,y are the coordinates after applying a normalization
%              transformation stored in FunNX and FunNY with parameters in
%              ParNX and ParNY, respectively.
%              add_par are additional parameters like color, airmass, and
%              parallactic angle.
% Variable naming: Class names has lower-case letter followed by "Cl".
%                  Properties names start with capital letter.
%                  Method names start with lower-case letter
%                  Variable names usually start with capital letter.
% Tested : Matlab R2018a
%     By : Eran O. Ofek                    Jun 2020
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Dependencies: 
% Example: % Construct a Tran2Dobject with 3rd order checyshev
%          T=Tran2D;
%          % Construct a design matrix, H, for the transformation
%          % such that x = Hx*Par
%          Coo = rand(10,2);
%          [Hx,Hy]=design_matrix(T,Coo)
% Reliable: 2
%--------------------------------------------------------------------------

classdef Tran2D < handle
    properties (SetAccess = public)
        ColCell     = {'x','y','c','AM','PA'};
        FunX        
        FunY        
        FunNX       = @(x,nx1,nx2) (x-nx1)./nx2;
        FunNY       = @(y,ny1,ny2) (y-ny1)./ny2;
        ParX        
        ParY        
        FitData        % a general structure to store errors and residuals of best fit
        ParNX       = [0 1];
        ParNY       = [0 1];
    end
    properties (SetAccess=protected)
        PolyRep     = struct('PX',[],'PY',[],'CX',[],'CY',[],'PolyParX',[],'PolyParY',[],...
                             'PolyX_Xdeg',[],'PolyX_Ydeg',[],'PolyY_Xdeg',[],'PolyY_Ydeg',[]);
    end
        
    properties (Hidden)
        UserData
    end
    
    
    %-------------------
    %--- Constructor ---
    %-------------------
    methods
       
        function AstC=Tran2D(varargin)
            % Tran2D class constructor
            % Package: @Tran2D
            % Input  : * Arbitrary number of strings each represents
            %            a transformation functionals (see
            %            Tran2D.selected_trans for options).
            %            Each transformation will populate one element.
            %            Alternatively, this is a number of elements.
            %            Default is 'cheby1_3_c1'.
            % Output : - A Tran2D object
            % Example: TC=Tran2D
            %          TC=Tran2D(2)
            %          TC=Tran2D('cheby1_3_c1','cheby1_2');

            Def.Trans = 'cheby1_3_c1';
            if nargin==0
                varargin{1} = Def.Trans;
            end
            
            if numel(varargin)==1 && isnumeric(varargin{1})
                N = varargin{1};
                varargin = cell(1,N);
                [varargin{1:N}] = deal(Def.Trans);
            end
            
            
            Narg = numel(varargin);
            for Iarg=1:1:Narg
                AstC(Iarg).UserData = [];
                [FunX,FunY,ColCell] = Tran2D.selected_trans(varargin{Iarg});
                AstC(Iarg).FunX     = FunX;
                AstC(Iarg).FunY     = FunY;
                AstC(Iarg).ColCell  = ColCell;
            end
                
        end

    end
    
    % setters/getters
    methods
        function set.FunX(TC,FX)
            % setter for the Tran2D FunX property
           
            if iscell(FX)
                TC.FunX = FX;
            else
                if ischar(FX)
                    %
                else
                    error('Non cell/str array FunX input is not supported');
                end
            end
            
            TC.PolyRep = struct('PX',[],'PY',[],'CX',[],'CY',[],'PolyParX',[],'PolyParY',[],...
                             'PolyX_Xdeg',[],'PolyX_Ydeg',[],'PolyY_Xdeg',[],'PolyY_Ydeg',[]);
            
        end
        
        function set.FunY(TC,FY)
            % setter for the Tran2D FunY property
           
            if ~iscell(FY)
                error('Non cell array FunY input is not supported');
            end
            TC.FunY = FY;
            TC.PolyRep = struct('PX',[],'PY',[],'CX',[],'CY',[],'PolyParX',[],'PolyParY',[],...
                             'PolyX_Xdeg',[],'PolyX_Ydeg',[],'PolyY_Xdeg',[],'PolyY_Ydeg',[]);
            
        end
        
        function set.ColCell(TC,CC)
            % setter for the Tran2D ColCell property
            
            if ~iscell(CC)
                error('Non cell array ColCell input is not supported');
            end
            
            TC.ColCell = CC;
        end
 
        
    end
    
    % 
    methods (Static)
        function Ans=isTran2D(Obj)
            % Check if object is a Tran2D object
            % Package: @Tran2D (Static)
            % Example: Tran2D.isTran2D(Obj)
            
            if isa(Obj,'Tran2D')
                Ans = true;
            else
                Ans = false;
            end
        end
        
        % built in transformations
        function [FunX,FunY,ColCell]=selected_trans(Name)
            % Return predefined 2d transformations
            % Package: @Tran2D (Static)
            % Input  : - Transformation name. Avialable transformations
            %            are:
            %            'cheby1_3_c1' - Fitsr kind Chebyshev polynomials
            %                   of the 3rd degree + color term of the first degree.
            %            'cheby1_3' -  Fitsr kind Chebyshev polynomials
            %                   of the 3rd degree.
            %            'cheby1_4' -  Fitsr kind Chebyshev polynomials
            %                   of the 4th degree.
            %            'cheby1_4_c1' - Fitsr kind Chebyshev polynomials
            %                   of the 4th degre + color term of the first degree.
            %            'cheby1_2' -  Fitsr kind Chebyshev polynomials
            %                   of the 2nd degree.
            %            'poly1' - 1st deg poynomials.
            %            'poly2' - 2nd deg polynomials.
            %            'poly1_tiptilt' - 1st deg polynomials + 2 tip/tilt
            %                   terms.
            % Output : - A cell array of functionals for X coordinates.
            %          - A cell array of functionals for Y coordinates.
            %          - A cell array of argume names.
            %            By default this is {'x','y','c','AM','PA'}.
            % Example:
            % [FunX,FunY,ColCell]=Tran2D.selected_trans('cheby1_3_c1')
            
            switch lower(Name)
                case 'cheby1_3_c1'
                    % chebyshev polynomials of the first kind, of order 3 +
                    % color terms of the first order
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) 2.*x.^2-1,...
                                      @(x,y,c,AM,PA) 2.*y.^2-1,...
                                      @(x,y,c,AM,PA) x.*y,...
                                      @(x,y,c,AM,PA) 4.*x.^3 - 3.*x,...
                                      @(x,y,c,AM,PA) 4.*y.^3 - 3.*y,...
                                      @(x,y,c,AM,PA) (2.*x.^2-1).*y,...
                                      @(x,y,c,AM,PA) (2.*y.^2-1).*x,...
                                      @(x,y,c,AM,PA) c,...
                                      @(x,y,c,AM,PA) x.*c,...
                                      @(x,y,c,AM,PA) y.*c};
                    FunY        = FunX;
                   
                case 'cheby1_3'
                    % chebyshev polynomials of the first kind, of order 3
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) 2.*x.^2-1,...
                                      @(x,y,c,AM,PA) 2.*y.^2-1,...
                                      @(x,y,c,AM,PA) x.*y,...
                                      @(x,y,c,AM,PA) 4.*x.^3 - 3.*x,...
                                      @(x,y,c,AM,PA) 4.*y.^3 - 3.*y,...
                                      @(x,y,c,AM,PA) (2.*x.^2-1).*y,...
                                      @(x,y,c,AM,PA) (2.*y.^2-1).*x};
                    FunY        = FunX;
                case 'cheby1_4'
                    % chebyshev polynomials of the first kind, of order 4
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) 2.*x.^2-1,...
                                      @(x,y,c,AM,PA) 2.*y.^2-1,...
                                      @(x,y,c,AM,PA) x.*y,...
                                      @(x,y,c,AM,PA) 4.*x.^3 - 3.*x,...
                                      @(x,y,c,AM,PA) 4.*y.^3 - 3.*y,...
                                      @(x,y,c,AM,PA) (2.*x.^2-1).*y,...
                                      @(x,y,c,AM,PA) (2.*y.^2-1).*x,...
                                      @(x,y,c,AM,PA) (8.*x.^4 - 8.*x.^2 + 1),...
                                      @(x,y,c,AM,PA) (8.*y.^4 - 8.*y.^2 + 1),...
                                      @(x,y,c,AM,PA) (4.*x.^3 - 3.*x).*y,...
                                      @(x,y,c,AM,PA) (4.*y.^3 - 3.*y).*x,...
                                      @(x,y,c,AM,PA) (2.*x.^2-1).*(2.*y.^2-1)};
                                      
                    FunY        = FunX;
                case 'cheby1_4_c1'
                    % chebyshev polynomials of the first kind, of order 4
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) 2.*x.^2-1,...
                                      @(x,y,c,AM,PA) 2.*y.^2-1,...
                                      @(x,y,c,AM,PA) x.*y,...
                                      @(x,y,c,AM,PA) 4.*x.^3 - 3.*x,...
                                      @(x,y,c,AM,PA) 4.*y.^3 - 3.*y,...
                                      @(x,y,c,AM,PA) (2.*x.^2-1).*y,...
                                      @(x,y,c,AM,PA) (2.*y.^2-1).*x,...
                                      @(x,y,c,AM,PA) (8.*x.^4 - 8.*x.^2 + 1),...
                                      @(x,y,c,AM,PA) (8.*y.^4 - 8.*y.^2 + 1),...
                                      @(x,y,c,AM,PA) (4.*x.^3 - 3.*x).*y,...
                                      @(x,y,c,AM,PA) (4.*y.^3 - 3.*y).*x,...
                                      @(x,y,c,AM,PA) (2.*x.^2-1).*(2.*y.^2-1),...
                                      @(x,y,c,AM,PA) c,...
                                      @(x,y,c,AM,PA) x.*c,...
                                      @(x,y,c,AM,PA) y.*c};
                                      
                    FunY        = FunX;
                case 'cheby1_2'
                    % chebyshev polynomials of the first kind, of order 3
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) 2.*x.^2-1,...
                                      @(x,y,c,AM,PA) 2.*y.^2-1,...
                                      @(x,y,c,AM,PA) x.*y};
                                      
                    FunY        = FunX;
                case 'poly1'
                    % chebyshev polynomials of the first kind, of order 3
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y};
                                      
                    FunY        = FunX;                 
                case 'poly2'
                    % chebyshev polynomials of the first kind, of order 3
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) x.^2,...
                                      @(x,y,c,AM,PA) y.^2,...
                                      @(x,y,c,AM,PA) x.*y};
                    FunY        = FunX;     
                    
                case 'poly1_tiptilt'
                    % chebyshev polynomials of the first kind, of order 3
                    ColCell     = {'x','y','c','AM','PA'};
                    FunX        = {@(x,y,c,AM,PA) ones(size(x)),...
                                      @(x,y,c,AM,PA) x,...
                                      @(x,y,c,AM,PA) y,...
                                      @(x,y,c,AM,PA) x.*(x+y),...
                                      @(x,y,c,AM,PA) y.*(x+y)};
                    FunY        = FunX;      
                otherwise
                    error('Unknown predefined functionals');
            end
            
        end
    end
    
    % transformations
    methods
        function [Hx,Hy]=design_matrix(TC,Coo)
            % construct design matrices for a position
            % Package: @Tran2D
            % Description: Construct a design matrices (for X and Y
            %              coordinates) given a Tran2D object and a list
            %              of coordinates. The coordinates must contain at
            %              least two columns [X,Y], but may include
            %              additional coordinates (e.g., Color, AM, PA).
            % Input  : - A Tran2D object
            %          - A matrix of coordinates with minimum of two
            %            columns [X,Y].
            %            The i-th column is the i-th input argument of each
            %            one of the functionals in FunX, FunY.
            %            The X and Y coordinates are normalized using the
            %            FunNX and FunNY functions.
            %            Alternatively, this can be an N-element cell
            %            array, where each element contains a vector of
            %            coordinates.
            % Output : - Design matrix of X coordinates.
            %          - Design matrix of Y coordinates.
            % Example: [Hx,Hy]=design_matrix(T,[1 1])
            
            Ncoo = numel(TC.ColCell);  % number of coordinates
            
            if iscell(Coo)
                [Ncol] = numel(Coo);    % number of supplied coordinates
                Npt    = numel(Coo{1});
                CooCol = Coo;
            else
                
                [Npt,Ncol] = size(Coo);    % number of supplied coordinates
                if Ncol<2
                    error('Number of coordinates must be 2 or more');
                end

                % pad by zeros
                Coo    = [Coo, zeros(Npt,Ncoo-Ncol)];
                % CooCol is a cell arrat of coordinates
                CooCol = mat2cell(Coo,Npt,ones(1,Ncoo));
            end
            
            % coordinates normalization
            CooCol{1} = TC.FunNX(CooCol{1},TC.ParNX(1),TC.ParNX(2));
            CooCol{2} = TC.FunNY(CooCol{2},TC.ParNY(1),TC.ParNY(2));
            
            NparX = numel(TC.FunX);
            Hx    = zeros(Npt,NparX);
            for Ix=1:1:NparX
                Hx(:,Ix) = TC.FunX{Ix}(CooCol{:});
            end

            NparY = numel(TC.FunY);
            Hy    = zeros(Npt,NparY);
            for Iy=1:1:NparY
                Hy(:,Iy) = TC.FunY{Iy}(CooCol{:});
            end

        end
        
        function [NfunX,NfunY]=nfuns(TC)
            % count number of free linear parameters in FunX and FunY
            % Package: @trand2Cl
            % Input  : - A Tran2D object
            % Output : - Number of functionals (or free parameters) in X.
            %          - Number of functionals (or free parameters) in Y.
           
            if iscell(TC.FunX)
                NfunX = numel(TC.FunX);
            else
                error('Unrecognaized FunX format');
            end
            if iscell(TC.FunY)
                NfunY = numel(TC.FunY);
            else
                error('Unrecognaized FunY format');
            end
            
        end
            
        function Ans=isParKnown(TC)
            % Check if number of parameters is consistent with number of functionals.
            % Package: @Tran2D
            % Input  : - A Tran2D object.
            % Output : - True if number of parameters equal to the number
            %            of functionals in both X and Y. Otherwise false.
            
            [NfunX,NfunY] = nfuns(TC);
            NparX = numel(TC.ParX);
            NparY = numel(TC.ParY);
            
            if (NparX==NfunX && NparY==NfunY)
                Ans = true;
            else
                Ans = false;
            end
            
            
        end
        
        function [Xf,Yf]=forward(TC,Coo)
            % Applay forward transformation to coordinates
            % Package: @Tran2D
            % Input  : - A Tran2D object
            %          - A matrix of coordinates, line per point.
            %            The matrix must contains at least two columns
            %            [X,Y]. The other columns are assumed to be the
            %            coordinates listed in the ColCell property of the
            %            Tran2D object. If the other coordinates are not
            %            provided then they assumed to be zero.
            % Output : - X coordinate after applaying the forward
            %            transformation.
            %          - Y coordinate after applaying the forward
            %            transformation.
            % Example: TC=Tran2D; TC.ParY=ones(1,13);  TC.ParX=ones(1,13); 
            %          [Xf,Yf]=forward(TC,[1 1;2 1])
            
            % applay normalization
            Normalize = true;
            if Normalize
                if iscell(Coo)
                    Xref = TC.FunNX(Coo{1},TC.ParNX(1),TC.ParNX(2));
                    Yref = TC.FunNX(Coo{2},TC.ParNY(1),TC.ParNY(2));
                else
                    Xref = TC.FunNX(Coo(:,1),TC.ParNX(1),TC.ParNX(2));
                    Yref = TC.FunNX(Coo(:,2),TC.ParNY(1),TC.ParNY(2));
                end
                Coo = [Xref(:), Yref(:)];
            end
           
            % design matrix
            [Hx,Hy] = design_matrix(TC,Coo);
            
            if ~isParKnown(TC)
                error('In order to perform transformation parameter must be provided');
            end
            
            Xf = Hx*TC.ParX(:);
            Yf = Hy*TC.ParY(:);
            
        end
            
        function [X,Y]=backward(TC,Coo)
            % Applay backward transformation to coordinates
            % Package: @Tran2D
            % Input  : - A Tran2D object
            %          - A matrix of coordinates, line per point.
            %            The matrix must contains at least two columns
            %            [X,Y]. The other columns are assumed to be the
            %            coordinates listed in the ColCell property of the
            %            Tran2D object. If the other coordinates are not
            %            provided then they assumed to be zero.
            % Output : - X coordinate after applaying the backward
            %            transformation.
            %          - Y coordinate after applaying the backward
            %            transformation.
            % Example: TC=Tran2D; TC.ParY=zeros(1,13);  TC.ParX=zeros(1,13); 
            %          TC.ParX(1:2) = 1; TC.ParX(5)=0.03; TC.ParX(7)=0.01;
            %          TC.ParY(1) = 2; TC.ParY(3)=1.01; TC.ParY(5)=0.01; TC.ParY(8)=0.001;
            %          [Xf,Yf]=forward(TC,[1 1.3;2 6;3 3]);
            %          [X,Y]=backward(TC,[Xf, Yf]);
            
            Step = 1e-5;
            Threshold = 1e-5;
            MaxIter   = 20;
            
            Ncoo = numel(TC.ColCell);  % number of coordinates
            [Npt,Ncol] = size(Coo);    % number of supplied coordinates
            if Ncol<2
                error('Number of coordinates must be 2 or more');
            end

            % pad by zeros
            Coo    = [Coo, zeros(Npt,Ncoo-Ncol)];
            % CooCol is a cell array of coordinates
            CooCell = mat2cell(Coo,Npt,ones(1,Ncoo));
            
            Xf = CooCell{1};
            Yf = CooCell{2};
            
            Xi  = Xf;
            Yi  = Yf;
            
            % The ouput from forward should be the input Xf, Yf
            NotConverged = true;
            Iter = 0;
            while NotConverged
                %
                Iter = Iter + 1;
                
                CooCell{1} = Xi;
                CooCell{2} = Yi;
                [Xi1,Yi1] = forward(TC,CooCell);
                CooCell{1} = Xi + Step;
                CooCell{2} = Yi + Step;
                [Xi2,Yi2] = forward(TC,CooCell);
                
                DeltaX = (Xi1 - Xi2);
                DeltaY = (Yi1 - Yi2);
                
                IncX = (Xi1 - Xf)./DeltaX .* Step;
                IncY = (Yi1 - Yf)./DeltaY .* Step;
                Xi = Xi + IncX;
                Yi = Yi + IncY; 
                
                CooCell{1} = Xi;
                CooCell{2} = Yi;
                [Xi1,Yi1] = forward(TC,CooCell);
                DiffX = Xi1 - Xf;
                DiffY = Yi1 - Yf;
                
                if max(abs(DiffX))<Threshold && max(abs(DiffY))<Threshold
                    NotConverged = false;
                end
                if Iter>MaxIter
                    NotConverged = false;
                    error('Tran2D.backward didnot converge after %d iterations',Iter);
                end
                
            end
            
            X = Xi;
            Y = Yi;
        
        end
        
    end
    
    % fitting
    methods
        function TC=fit_simple(TC,RefXY,Z)
            % A simple fit (no errors/iterations) of a data to the transformation
            % Package: @Tran2D
            % Input  : - An Tran2D object
            %          - A matrix of reference [X, Y] coordinates to fit.
            %          - A vector of catalog X or Y coordinates to fit.
            % Output : - The Tran2D object with the best fit parameters.
            
            N = numel(TC);
            for I=1:1:N
                [Hx,Hy] = design_matrix(TC(I),RefXY);

                ParX = Hx\Z;
                ParY = Hy\Z;

                TC(I).ParX = ParX;
                TC(I).ParY = ParY;
            end
            
            
        end
        
    end
    
    
    % convert to wcsCl
    methods
        function W=Tran2D2wcsCl(T,varargin)
            %
            % Example:
            % W=Tran2D2wcsCl(Res.Tran,'TranCenter',Res.TranCenter)
            
            InPar = inputParser;
            addOptional(InPar,'RA',[]);
            addOptional(InPar,'Dec',[]);
            addOptional(InPar,'CooUnits','deg');
            addOptional(InPar,'Scale',[]);
            addOptional(InPar,'CRPIX',[]);  
            addOptional(InPar,'EQUINOX',2000);  
            addOptional(InPar,'TranCenter',[]);  % a structure that contains all the fields
            parse(InPar,varargin{:});
            InPar = InPar.Results;

            if numel(T)>1
                error('works on a single element Tran2D object');
            end
            
            if ~isempty(InPar.TranCenter)
                InPar  = InPar.TranCenter;
            end
            
            W = wcsCl;
            W. NAXIS   = 2;
            W.WCSAXES  = 2;
            W.CUNIT    = {InPar.CooUnits, InPar.CooUnits};
            W.RADESYS  = 'ICRS';
            W.LONPOLE  = 0;
            W.LATPOLE  = 90;
            W.EQUINOX  = InPar.EQUINOX;
            W.CRPIX    = InPar.CRPIX;
            W.CRVAL    = [InPar.RA, InPar.Dec];
            W.CD       = [1 0;0 1];
            W.fill;
            W.ProjType   = 'TPV';
            W.ProjClass  = wcsCl.classify_projection(W.ProjType);
            W.CooName    = {'RA','Dec'};
            % define PhiP
            W.PhiP       = 180;
            
            % build polynomial representation
            T.polyRep;
            
            % order T.PolyRep.PolyX_Xdeg etc. in the PV cell
            % store PolyParX...
            [IndX,PolyPV] = wcsCl.poly2tpvInd(T.PolyRep.PolyX_Xdeg, T.PolyRep.PolyX_Ydeg);
            W.PV{1} = [IndX(:), T.ParX(:)];
            [IndY,PolyPV] = wcsCl.poly2tpvInd(T.PolyRep.PolyY_Xdeg, T.PolyRep.PolyY_Ydeg);
            W.PV{2} = [IndX(:), T.ParY(:)];
            W.fill_PV;
            W.Exist = true;
            
            
            
        end
        
    end
    
    methods (Static)
        function [CX,CY,PX,PY]=functionals2symPoly(ColCell,FunX,FunY,FunNX,FunNY)
            % Construct a symbolic polynomials from a functionals object
            % Package: @Tran2D (Static)
            % Description: Given a cell array of anonymous function in X and Y,
            %              and normalization anonymous function, and a cell
            %              array of argument names. Construct an array of
            %              symbolic polynomials and their coefficients.
            % Input  : - A Tran2D object.
            % Output : - A vector of symbolic functions, one per X
            %            functional. These are the coefficients of the
            %            polynomial that represents the FunX functionals.
            %          - The same but for Y.
            %          - A cector of symbolic functions, one per X
            %            functional. These are the polynomial terms
            %            corresponding for each of the coefficients.
            %          - The same but for Y.
            % Example: TC=Tran2D;
            %          [CX,CY,PX,PY]=Tran2D.functionals2symPoly(TC.ColCell,TC.FunX,TC.FunY,TC.FunNX,TC.FunNY);
            
            NfunX = numel(FunX);
            NfunY = numel(FunY);
            % define syms arguments: x,y,c,AM,PA,...
            Ncoo = numel(ColCell);
            for Icoo=1:1:Ncoo
                syms(ColCell{Icoo});
            end
            for Ifx=1:1:NfunX
                CoefXstr = sprintf('cx%d',Ifx);
                syms(CoefXstr);
                FS = subs(sym(FunX{Ifx}),x,sym(FunNX));
                FS = subs(sym(FS),y,sym(FunNY));
                if Ifx==1
                    AllFunX = eval(CoefXstr)*FS;
                else
                    AllFunX = AllFunX + eval(CoefXstr)*FS;
                end
                
            end
            [CX,PX]=coeffs(AllFunX,[x y]);
            
            for Ify=1:1:NfunY
                CoefYstr = sprintf('cy%d',Ify);
                syms(CoefYstr);
                FS = subs(sym(FunY{Ify}),x,sym(FunNX));
                FS = subs(sym(FS),y,sym(FunNY));
                if Ify==1
                    AllFunY = eval(CoefYstr)*FS;
                else
                    AllFunY = AllFunY + eval(CoefYstr)*FS;
                end
                
            end
            [CY,PY]=coeffs(AllFunY,[x y]);
            
        end
        
        function [PolyCoefX, PolyCoefY]=functionals2polyCoef(CX,CY,PX,PY,ColCell,ParX,ParY,ParNX,ParNY,ParExtra)
            % Convert functionals and parameters to polynomial coefficients
            % Package: @Tran2D (Static)
            % Description: Given functionals and their polynomial
            %              representation generated by
            %              Tran2D.functionals2symPoly, collect the
            %              polynomial coeffocients and calculate their
            %              values.
            % Input  : - CX (output of Tran2D.functionals2symPoly)
            %          - CY (output of Tran2D.functionals2symPoly)
            %          - PX (output of Tran2D.functionals2symPoly)
            %          - PY (output of Tran2D.functionals2symPoly)
            %          - Cell array of functional argument names.
            %          - Values of the parameters of the X functionals.
            %          - Values of the parameters of the Y functionals.
            %          - Values of the parameters of the X normalization.
            %          - Values of the parameters of the Y normalization.
            %          - The values of the additional coordinates.
            %            Default is 0 for all coordinates.
            % Output : - Vector of coefficients of the polynomials in PX.
            %          - Vector of coefficients of the polynomials in PY.
            
            if nargin<10
                ParExtra = [];
            end
                        
            for Ix=1:1:numel(ParX)
                CoefXstr = sprintf('cx%d = ParX(Ix);',Ix);
                eval(CoefXstr)
            end
            eval('nx1 = ParNX(1);');
            eval('nx2 = ParNX(2);');
            
            for Iy=1:1:numel(ParY)
                CoefYstr = sprintf('cy%d = ParY(Iy);',Iy);
                eval(CoefYstr)
            end
            
            
            eval('ny1 = ParNY(1);');
            eval('ny2 = ParNY(2);');
            
            % additional parameters
            Ncoo = numel(ColCell);
            % skip over x and y
            Iex = 0;
            for Icoo=3:1:Ncoo
                Iex = Iex + 1;
                if isempty(ParExtra)
                    eval(sprintf('%s = 0;',ColCell{Icoo}));
                else
                    eval(sprintf('%s = ParExtra(Iex);',ColCell{Icoo}));
                end
            end
            
            PolyCoefX = eval(CX);
            PolyCoefY = eval(CY);
                       
        end
        
    end
    
    % symbolic
    methods
        function [CX,CY,PX,PY]=symPoly(TC)
            % Construct a symbolic polynomials from a Tran2D object
            % Package: @Tran2D
            % Description: Construct a symbolic polynomials from a
            %              Tran2D object using Tran2D.functionals2symPoly
            %              and store the symbolic functions in the PolyRep
            %              property.
            %              This function update the PolyRep.PX,PY,CX,CY
            %              properties. If these properties already exist,
            %              then they will not be calculated again.
            % Input  : - A Tran2D object.
            % Output : - A vector of symbolic functions, one per X
            %            functional. These are the coefficients of the
            %            polynomial that represents the FunX functionals.
            %          - The same but for Y.
            %          - A cector of symbolic functions, one per X
            %            functional. These are the polynomial terms
            %            corresponding for each of the coefficients.
            %          - The same but for Y.
            % Example: [CX,CY,PX,PY]=symPoly(TC);
            
            if isempty(TC.PolyRep) || isempty(TC.PolyRep.PX)
                % check if already populated
                % This is posssible since the FunX and FunY setters delete
                % PolyRep
            
                [CX,CY,PX,PY] = Tran2D.functionals2symPoly(TC.ColCell,TC.FunX,TC.FunY,TC.FunNX,TC.FunNY);

                TC.PolyRep.PX = PX;
                TC.PolyRep.PY = PY;
                TC.PolyRep.CX = CX;
                TC.PolyRep.CY = CY;
                TC.PolyRep.PolyParX = [];
                TC.PolyRep.PolyParY = [];
                
            else
                PX = TC.PolyRep.PX;
                PY = TC.PolyRep.PY;
                CX = TC.PolyRep.CX;
                CY = TC.PolyRep.CY;
            end
            
            
        end
       
        function [PolyCoefX, PolyCoefY, PX, PY]=polyCoef(TC,varargin)
            % Convert a Tran2D object and parameters to polynomial coefficients
            % Package: @Tran2D
            % Description: Use Tran2D.functionals2polyCoef to populate
            %              the numerical value of the coefficients of the
            %              transfornmation polynomial representation.
            %              This function update the PolyRep.PolyParX and
            %              PolyRep.PolyParY in the Tran2D object.
            %              If these properties already exist,
            %              then they will not be calculated again.
            % Input  : - A Tran2D object.
            %          - Vector of the value for the additional parameters in
            %            TC.ColCell after [x,y]. For example, if ColCell is
            %            {'x','y','c','AM',PA'}, then these are the value
            %            of 'c','AM','PA' at which the polynomials coef.
            %            are evaluate at.
            %            Default is 0 for all the parameters.
            % Output : - Vector of the values of the numerical coefficients
            %            of the polynomial representation of FunX.
            %          - Vector of the values of the numerical coefficients
            %            of the polynomial representation of FunY.
            %          - An array of symbolic polynomials corresponding to
            %            the coeffcients in X.
            %          - An array of symbolic polynomials corresponding to
            %            the coeffcients in Y.
            % Example: TC = Tran2D;  TC.symPoly
            %          TC.polyCoef
            
            if isempty(TC.ParX)
                error('ParX must be populated');
            end
            if isempty(TC.ParY)
                error('ParY must be populated');
            end
            
            if isempty(TC.PolyRep) || isempty(TC.PolyRep.PX)
                [CX,CY,PX,PY]=symPoly(TC);
            else
                CX = TC.PolyRep.CX;
                CY = TC.PolyRep.CY;
                PX = TC.PolyRep.PX;
                PY = TC.PolyRep.PY;
            end
                
            if isempty(TC.PolyRep.PolyParX) || isempty(TC.PolyRep.PolyParY)
                [PolyCoefX, PolyCoefY] = Tran2D.functionals2polyCoef(CX,CY,PX,PY,TC.ColCell,TC.ParX,TC.ParY,TC.ParNX,TC.ParNY,varargin{:});
                TC.PolyRep.PolyParX = PolyCoefX;
                TC.PolyRep.PolyParY = PolyCoefY;
            else
                PolyCoefX = TC.PolyRep.PolyParX;
                PolyCoefY = TC.PolyRep.PolyParY;
            end
                
            
            
        end
        
        function [PolyX_Xdeg,PolyX_Ydeg,PolyY_Xdeg,PolyY_Ydeg]=symPoly2deg(TC)
            % Return the X and Y poly deg vectors of the polynomial representations
            % Package: @Tran2D
            % Description: The PolyRep.PX/PY contains the symbolic
            %              polynomial representation. This function
            %              calculate the deg of X and Y polynomial in each
            %              elemnt of the symbolic vector. For example, for
            %              PX with x^3*y it will return: PolyX_Xdeg=3
            %              and PolyX_Ydeg=1.
            %              If these properties already exist,
            %              then they will not be calculated again.
            % Input  : - A Tran2D object
            % Output : - A vector of the polynomial degrees of X in the
            %            PolyRep.PX vector.
            %          - A vector of the polynomial degrees of Y in the
            %            PolyRep.PX vector.
            %          - A vector of the polynomial degrees of X in the
            %            PolyRep.PY vector.
            %          - A vector of the polynomial degrees of Y in the
            %            PolyRep.PY vector.
            % Example: [PolyX_Xdeg,PolyX_Ydeg,PolyY_Xdeg,PolyY_Ydeg]=symPoly2deg(TC)
            
            if isempty(TC.PolyRep.PolyX_Xdeg)
                syms x y
                PolyX_Xdeg = polynomialDegree(TC.PolyRep.PX,x);
                PolyX_Ydeg = polynomialDegree(TC.PolyRep.PX,y);
                PolyY_Xdeg = polynomialDegree(TC.PolyRep.PY,x);
                PolyY_Ydeg = polynomialDegree(TC.PolyRep.PY,y);
                
                TC.PolyRep.PolyX_Xdeg = PolyX_Xdeg;
                TC.PolyRep.PolyX_Ydeg = PolyX_Ydeg;
                TC.PolyRep.PolyY_Xdeg = PolyY_Xdeg;
                TC.PolyRep.PolyY_Ydeg = PolyY_Ydeg;
                
            else
                PolyX_Xdeg = TC.PolyRep.PolyX_Xdeg;
                PolyX_Ydeg = TC.PolyRep.PolyX_Ydeg;
                PolyY_Xdeg = TC.PolyRep.PolyY_Xdeg;
                PolyY_Ydeg = TC.PolyRep.PolyY_Ydeg;
            end
            
            
        end
        
        function TC=polyRep(TC,Force)
            % Update the PolyRep polynomial representation property
            % Package: @Tran2D
            % Description: Update or populate the PolyRep property in the
            %              Tran2D object. This propert contains the
            %              polynomial representation of the transformation
            %              object.
            % Input  : - A Tran2D object.
            %          - A logical parameter indicating if to re-populate
            %            PolyRep property even if it is already exist
            %            (true), or to calculate it only if it doesn't
            %            exist (false).
            %            Default is false.
            % Output : null - update the PolyRep property
            % Example: TC.polyRep
            
            if nargin<2
                Force = false;
            end
            
            if Force || isempty(TC.PolyRep.PX) || isempty(TC.PolyRep.PolyParX) || isempty(TC.PolyRep.PolyX_Xdeg)
                % re-calculate polynomial representation
                TC.symPoly;
                TC.polyCoef;
                TC.symPoly2deg;
            end
            
        end
        
    end
    
    
    methods (Static)  % unitTest
        function Result = unitTest
            % unitTest for Tran2D class
            % Example: Tran2D.unitTest
            
            io.msgLog(LogLevel.Test, 'testing Tran2D constructors');
            T=Tran2D;
            
            TC = Tran2D;
            TC = Tran2D(2);
            TC = Tran2D('cheby1_3_c1','cheby1_2');
            
            io.msgLog(LogLevel.Test, 'testing Tran2D design_matrix');
            [Hx,Hy]=design_matrix(T,rand(10,2));
            
            io.msgLog(LogLevel.Test, 'testing Tran2D nfuns');
            [NfunX,NfunY]=nfuns(T);
            Ans=isParKnown(T);
            TC=Tran2D; TC.ParY=ones(1,13);  TC.ParX=ones(1,13); 
            [Xf,Yf]=forward(TC,[1 1;2 1]);
            
            TC=Tran2D; TC.ParY=zeros(1,13);  TC.ParX=zeros(1,13); 
            TC.ParX(1:2) = 1; TC.ParX(5)=0.03; TC.ParX(7)=0.01;
            TC.ParY(1) = 2; TC.ParY(3)=1.01; TC.ParY(5)=0.01; TC.ParY(8)=0.001;
            XY = [1 2; 1.1 0.2; 0.3 2.1];
            
            io.msgLog(LogLevel.Test, 'testing Tran2D forward, backward');
            [Xf,Yf]=forward(TC,XY);
            [X,Y]=backward(TC,[Xf, Yf]);
            
            if ~all(abs(XY - [X, Y])<1e-4)
                error('Forward/backward transformation faild');
            end
            
            % symbolic representations
            io.msgLog(LogLevel.Test, 'testing Tran2D functionals2simPoly');
            TC=Tran2D;
            [CX,CY,PX,PY]=Tran2D.functionals2symPoly(TC.ColCell,TC.FunX,TC.FunY,TC.FunNX,TC.FunNY);
            io.msgLog(LogLevel.Test, 'testing Tran2D symPoly');
            [CX,CY,PX,PY]=symPoly(TC);
            TC = Tran2D;
            TC.symPoly;
            TC.ParX = ones(1,13);
            TC.ParY = ones(1,13);
            TC.polyCoef;
            io.msgLog(LogLevel.Test, 'testing Tran2D symPoly2deg');
            [PolyX_Xdeg,PolyX_Ydeg,PolyY_Xdeg,PolyY_Ydeg]=symPoly2deg(TC);
            TC.ParX = ones(1,13);
            TC.ParY = ones(1,13);
            TC.polyRep;
            
            % selected_trans
            io.msgLog(LogLevel.Test, 'testing Tran2D selected_trans');
            [FunX,FunY,ColCell]=Tran2D.selected_trans('cheby1_3_c1');
            
            % tran2d2wcs
%             TC = Tran2D('cheby1_3_c1');
%             W=Tran2D2wcsCl(TC); <-- doesn't work
            io.msgStyle(LogLevel.Test, '@passed', 'Tran2D test passed');
            
            Result = true;
            
        end
        
    end
    
end

            
