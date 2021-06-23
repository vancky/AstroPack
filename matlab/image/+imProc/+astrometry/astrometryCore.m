function Result = astrometryCore(Obj, Args)
    %
    % Example: 
   
    arguments
        Obj(1,1) AstroCatalog
        Args.RA
        Args.Dec
        Args.CooUnits                     = 'deg';
        Args.CatName                      = 'GAIAEDR3';  % or AstroCatalog
        Args.CatOrigin                    = 'catsHTM';
        Args.CatRadius                    = 1800;
        Args.CatRadiusUnits               = 'arcsec'
        Args.Con                          = {};
        
        Args.MagColName                   = {'Mag_BP','Mag'};
        Args.MagRange                     = [12 19];
        Args.PlxColName                   = {'Plx'};
        Args.PlxRange                     = [-Inf 10];
        
        Args.EpochOut                     = [];
        Args.argsProperMotion cell        = {};
        Args.argsFilterForAstrometry cell = {};
        Args.argsFitPattern cell          = {};
        
        Args.ProjType                     = 'TAN';
        
        Args.Scale                        = 1.0;      % range or value [arcsec/pix]
        Args.RotationRange(1,2)           = [-90, 90];
        Args.RotationStep(1,1)            = 0.2;
        
        Args.RangeX(1,2)                  = [-1000 1000]; 
        Args.RangeY(1,2)                  = [-1000 1000]; 
        Args.StepX(1,1)                   = 4;
        Args.StepY(1,1)                   = 4;
        Args.Flip(:,2)                    = [1 1; 1 -1;-1 1;-1 -1];
        Args.SearchRadius(1,1)            = 4;
        
        Args.Tran                         = Tran2D;
                
    end
    
    RotationEdges = (Args.RotationRange(1):Args.RotationStep:Args.RotationRange(2));
    % mean value of projection scale:
    ProjectionScale = (180./pi) .* 3600 ./ mean(Args.Scale);
    
    % Get astrometric catalog / incluidng proper motion
    % RA and Dec output are in radians
    [AstrometricCat, RA, Dec] = imProc.cat.getAstrometricCatalog(Args.RA, Args.Dec, 'CatName',Args.CatName,...
                                                                                    'CatOrigin',Args.CatOrigin,...
                                                                                    'Radius',Args.CatRadius,...
                                                                                    'RadiusUnits',Args.CatRadiusUnits,...
                                                                                    'CooUnits',Args.CooUnits,...
                                                                                    'OutUnits','rad',...
                                                                                    'Con',Args.Con,...
                                                                                    'EpochOut',Args.EpochOut,...
                                                                                    'argsProperMotion',Args.argsProperMotion);
        
    % Addtitional constraints on astrometric catalog
    % mag and parallax constraints
    AstrometricCat = queryRange(AstrometricCat, Args.MagColName, Args.MagRange,...
                                                Args.PlxColName, Args.PlxRange);
   
    % Project astrometric catalog
    ProjAstCat = imProc.trans.projection(AstrometricCat, RA, Dec, ProjectionScale, Args.ProjType, 'Coo0Units','rad',...
                                                                                                  'AddNewCols',{'X','Y'},...
                                                                                                  'CreateNewObj',false);
    % ProjAstCat.plot({'X','Y'},'.')   
    
    % filter astrometric catalog
    [FilteredCat, FilteredProjAstCat, Summary] = imProc.cat.filterForAstrometry(Obj, ProjAstCat, Args.argsFilterForAstrometry{:});
    
    % The Ref catalog is projected around some center that should coincide
    % with the center of Cat.
    % Therefore, we should shift Cat to its own center. ??
    
    
    
    % Match pattern catalog to projected astrometric catalog
    [ResPattern, Matched] = imProc.trans.fitPattern(FilteredCat, FilteredProjAstCat, Args.argsFitPattern{:},...
                                                                      'Scale',Args.Scale,...
                                                                      'HistRotEdges',RotationEdges,...
                                                                      'RangeX',Args.RangeX,...
                                                                      'RangeY',Args.RangeY,...
                                                                      'StepX',Args.StepX,...
                                                                      'StepY',Args.StepY,...
                                                                      'Flip',Args.Flip,...
                                                                      'SearchRadius',Args.SearchRadius);
    
    % go over possible solutions:
    
    %AffineMatrix = ResPattern.Sol.AffineTran{1}
    
    % Apply affine transformation to Reference
    % No need because this is also done in imProc.trans.fitPattern
    % TransformedCat = imProc.trans.tranAffine(Obj, AffineMatrix, true, 'RotUnits','deg'); 
    
    % Fit transformation
    %[Param, Res] = imProc.trans.fitTransformation(TransformedCat, FilteredProjAstCat, 'Tran',Args.Tran);
    % MatchedRef has the same number of lines as in Ref,
    % but it is affine transformed to the coordinate system of Cat
    [Param, Res] = imProc.trans.fitTransformation(Matched.MatchedCat, Matched.MatchedRef, 'Tran',Args.Tran);
    
    
    % Calculate WCS
    
    
end