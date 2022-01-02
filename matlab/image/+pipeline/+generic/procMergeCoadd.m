function [MergedCat, MatchedS, Coadd, ResultSubIm, ResultAsteroids, ResultCoadd] = procMergeCoadd(AllSI, Args)
    % Given a list of processed images, merged their catalogs, coadd
    % their images, and produce coadd catalogs.
    %   This is a basic generic pipeline conducting the following steps:
    %   0. Input is an array of processed images in which different epochs
    %      are in different lines, while different fields are in columns.
    %   1. Merge the catalogs for each field (columns of the input array)
    %      using imProc.match.mergeCatalogs
    %   2. Search asteroids using proper motions measured in the merged
    %      catalogs and using imProc.asteroids.searchAsteroids_pmCat
    %   3. Register the images of each field using their existing WCS and
    %      imProc.transIm.imwarp
    %   4. Coadd the images of each field using imProc.stack.coadd
    %   5. Measure background of coadd images using imProc.background.background
    %   6. Mask pixels dominated by source noise using imProc.mask.maskSourceNoise
    %   7. Find and measure sources using imProc.sources.findMeasureSources
    %   8. AStrometry of the coadd images using imProc.astrometry.astrometryRefine
    %   9. Photometric ZP of the coadd images using imProc.calib.photometricZP
    %   10. Match the coadd catalogs against the catsHTM MergedCat using
    %       imProc.match.match_catsHTMmerged
    % Input  : -
    % Output : -
    % Author : Eran Ofek (Jan 2022)
    % Example: 
    
    
    arguments
        AllSI
        Args.mergeCatalogsArgs cell           = {};
        Args.MergedMatchMergedCat logical     = true;
        Args.CoaddMatchMergedCat logical      = true;
        Args.coaddArgs cell                   = {'StackArgs',{'MeanFun',@mean, 'StdFun',@tools.math.stat.nanstd, 'Nsigma',[3 3], 'MaxIter',2}};
        Args.backgroundArgs cell              = {};
        Args.BackSubSizeXY                    = [128 128];
        Args.findMeasureSourcesArgs cell      = {};
        Args.ZP                               = 25;
        Args.ColCell cell                     = {'XPEAK','YPEAK',...
                                                 'X', 'Y',...
                                                 'X2','Y2','XY',...
                                                 'SN','BACK_IM','VAR_IM',...  
                                                 'BACK_ANNULUS', 'STD_ANNULUS', ...
                                                 'FLUX_APER', 'FLUXERR_APER',...
                                                 'MAG_APER', 'MAGERR_APER',...
                                                 'FLUX_CONV', 'MAG_CONV', 'MAGERR_CONV'};
        Args.Threshold                        = 5;
        Args.astrometryRefineArgs cell        = {};
        Args.Scale                            = 1.25;
        Args.Tran                             = Tran2D('poly3');
        Args.CatName                          = 'GAIAEDR3';
        Args.photometricZPArgs cell           = {};                                                              
        Args.ReturnRegisteredAllSI logical    = false;
          
        Args.StackMethod                      = 'sigmaclip';        
        Args.Asteroids_PM_MatchRadius         = 3;
    end
    
    % get JD
    JD = julday(AllSI(:,1));
    
    % merge catalogs
    % note that the merging works only on columns of AllSI !!!
    [MergedCat, MatchedS, ResultSubIm.ResZP, ResultSubIm.ResVar, ResultSubIm.FitMotion] = imProc.match.mergeCatalogs(AllSI,...
                                                                                                            Args.mergeCatalogsArgs{:},...
                                                                                                            'MergedMatchMergedCat',Args.MergedMatchMergedCat);
    
    % search for asteroids - proper motion channel
    [MergedCat, ResultAsteroids.AstCrop] = imProc.asteroids.searchAsteroids_pmCat(MergedCat,...
                                                                                  'BitDict',AllSI(1).MaskData.Dict,...
                                                                                  'JD',JD,...
                                                                                  'PM_Radius',Args.Asteroids_PM_MatchRadius,...
                                                                                  'Images',AllSI);
    
    % search for asteroids - orphan channel
    % imProc.asteroids.searchAsteroids_orphans
    
    % cross match with external catalogs
    
    % flag orphans
    
    
    % coadd images
    Nfields = numel(MatchedS);
    ResultCoadd = struct('ShiftX',cell(Nfields,1),...
                         'ShiftY',cell(Nfields,1),...
                         'CoaddN',cell(Nfields,1),...
                         'AstrometricFit',cell(Nfields,1),...
                         'ZP',cell(Nfields,1),...
                         'PhotCat',cell(Nfields,1)); % ini ResultCoadd struct
    Coadd       = AstroImage([Nfields, 1]);  % ini Coadd AstroImage
    for Ifields=1:1:Nfields
        ResultCoadd(Ifields).ShiftX = median(diff(MatchedS(Ifields).Data.X,1,1), 2, 'omitnan');
        ResultCoadd(Ifields).ShiftY = median(diff(MatchedS(Ifields).Data.Y,1,1), 2, 'omitnan');
    
        ShiftXY = cumsum([0 0; -[ResultCoadd(Ifields).ShiftX, ResultCoadd(Ifields).ShiftY]]);
        
        % no need to transform WCS - as this will be dealt later on
        % 'ShiftXY',ShiftXY,...
        % 'RefWCS',AllSI(1,Ifields).WCS,...
        RegisteredImages = imProc.transIm.imwarp(AllSI(:,Ifields),...
                                                 'ShiftXY',ShiftXY,...
                                                 'TransWCS',false,...
                                                 'FillValues',0,...
                                                 'ReplaceNaN',true,...
                                                 'CreateNewObj',~Args.ReturnRegisteredAllSI);
        
        % use sigma clipping...
        % 1. NOTE that the mean image is returned so that the effective gain
        % is now Gain/Nimages
        % 2. RegisteredImages has no header so no JD...
        [Coadd(Ifields), ResultCoadd(Ifields).CoaddN] = imProc.stack.coadd(RegisteredImages, Args.coaddArgs{:},...
                                                                                             'StackMethod',Args.StackMethod);
        
        
        
        % Background
        Coadd(Ifields) = imProc.background.background(Coadd(Ifields), Args.backgroundArgs{:},...
                                                                      'SubSizeXY',Args.BackSubSizeXY);
    
        
        % Mask Source noise dominated pixels
        Coadd(Ifields) = imProc.mask.maskSourceNoise(Coadd(Ifields), 'Factor',1, 'CreateNewObj',false);
        
        % Source finding
        Coadd(Ifields) = imProc.sources.findMeasureSources(Coadd(Ifields), Args.findMeasureSourcesArgs{:},...
                                                   'RemoveBadSources',true,...
                                                   'ZP',Args.ZP,...
                                                   'ColCell',Args.ColCell,...
                                                   'Threshold',Args.Threshold,...
                                                   'CreateNewObj',false);
                                           
                                           
        % astrometry    
        MeanJD = mean(JD);
        [ResultCoadd(Ifields).AstrometricFit, Coadd(Ifields), AstrometricCat] = imProc.astrometry.astrometryRefine(Coadd(Ifields), Args.astrometryRefineArgs{:},...
                                                                                                'WCS',AllSI(1,Ifields).WCS,...
                                                                                                'EpochOut',MeanJD,...
                                                                                                'Scale',Args.Scale,...
                                                                                                'CatName',Args.CatName,...
                                                                                                'Tran',Args.Tran,...
                                                                                                'CreateNewObj',false);

        
        % photometric calibration
        [Coadd(Ifields), ResultCoadd(Ifields).ZP, ResultCoadd(Ifields).PhotCat] = imProc.calib.photometricZP(Coadd(Ifields),...
                                                                                                    'CreateNewObj',false,...
                                                                                                    'MagZP',Args.ZP,...
                                                                                                    'CatName',AstrometricCat,...
                                                                                                    Args.photometricZPArgs{:});
        
        
        
    end
    
    % plot for LAST pipeline paper
    % semilogy(ResultCoadd(1).AstrometricFit.ResFit.RefMag, ResultCoadd(1).AstrometricFit.ResFit.Resid.*3600,'k.')
    % H=xlabel('$B_{\rm p}$ [mag]'); H.Interpreter='latex'; H.FontSize=18;                                 
    % H=ylabel('Residual [arcsec]'); H.Interpreter='latex'; H.FontSize=18;

    % semilogy(ResultCoadd(5).ZP.RefMag, abs(ResultCoadd(5).ZP.Resid),'k.')
    % H=xlabel('$B_{\rm p}$ [mag]'); H.Interpreter='latex'; H.FontSize=18;
    % H=ylabel('$|$Residual$|$ [mag]'); H.Interpreter='latex'; H.FontSize=18;
    
    % 
    
    
    if Args.CoaddMatchMergedCat
        % match against external catalogs
        Coadd = imProc.match.match_catsHTMmerged(Coadd, 'SameField',false, 'CreateNewObj',false);
    end
    
    
    
end
