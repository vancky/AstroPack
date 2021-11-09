function [MergedCat, MatchedS, Result] = mergeCatalogs(Obj, Args)
    %
    
    arguments
        Obj
        Args.CooType                 = 'sphere';
        Args.Radius                  = 2;
        Args.RadiusUnits             = 'arcsec';
        
        Args.RelPhot logical         = true;
        Args.fitPolyHyp logical      = true;
        Args.PolyDeg cell            = {[0], [0:1:1], [0:1:2], [0:1:3], [0:1:4], [0:1:5]};
        Args.FitPM logical           = true;
        Args.fitMotionArgs cell      = {'Prob',1e-5};
        
        Args.MatchedColums           = {'RA','Dec','X','Y','SN_1','SN_2','SN_3','SN_4','MAG_CONV_2','MAGERR_CONV_2','MAG_CONV_3','MAGERR_CONV_3','FLAGS'};
        
        Args.ColNameFlags            = 'FLAGS';
        Args.ColNamesStat            = {'MAG_CONV_2', 'MAG_CONV_3','SN_1','SN_2','SN_3','SN_4'};
        Args.FunIndStat              = {true, true, [1 3], [1 3], [1 3], [1 3]};
        Args.ColNamesAll             = {'MAG_CONV_2','MAGERR_CONV_2'};
        Args.MagCalibColName         = 'MAG_CONV_2';
        Args.MagCalibErrColName      = 'MAGERR_CONV_2';
        
    
        
        
        
        Args.ColPrefix cell          = {'Mean_', 'Med_', 'Std_', 'Err_'};
        Args.ColGeneratingFun        = {@mean, @median, @std, @tools.math.stat.mean_error};
        Args.GeneratingFunArgs       = { {1,'omitnan'}, {1,'omitnan'}, {[],1,'omitnan'}, {1} };
        Args.ColsToApplyFun          = {'RA','Dec','MAG_PSF'};   
        
        Args.ColName_PM_DeltaChi2    = 'PM_DeltaChi2';
        Args.ColName_PM_RA           = 'PM_RA';
        Args.ColName_PM_Dec          = 'PM_Dec';
        Args.ColName_Ep_RA           = 'EpochRA';
        Args.ColName_Ep_Dec          = 'EpochDec';
        Args.ColName_PM_ErrRA        = 'PM_ErrRA';
        Args.ColName_PM_ErrDec       = 'PM_ErrDec';
        Args.ColName_Ep_ErrRA        = 'EpochErrRA';
        Args.ColName_Ep_ErrDec       = 'EpochErrDec';
        
        Args.ColName_Nobs            = 'Nobs';   % if empty do not add
        Args.ColName_Epoch           = 'Epoch';
        Args.EpochUnits              = 'JD';
        
        Args.FitPoly(1,1) logical    = true;
        
        
        
        Args.unifiedSourcesCatalogArgs cell     = {};
        Args.matchArgs cell          = {};
        
    end
    
    % find all unique sources
    [Nepochs, Nfields] = size(Obj);
    JD  = julday(Obj(:,1));     

    for Ifields=1:1:Nfields
        [~, ~, Matched(Ifields,:)] = imProc.match.unifiedSourcesCatalog(Obj(:,Ifields), 'CooType',Args.CooType,...
                                                         'Radius',Args.Radius,...
                                                         'RadiusUnits',Args.RadiusUnits,...
                                                         Args.unifiedSourcesCatalogArgs{:});
                                                     
        MatchedS(Ifields) = MatchedSources;
        MatchedS(Ifields).addMatrix(Matched(Ifields,:), Args.MatchedColums);
        % populate JD
        MatchedS(Ifields).JD = JD;  
        
        % image 2 image X shift (pix)
        Summary(Ifields).ShiftX = median(diff(MatchedS(Ifields).Data.X,1,1), 2, 'omitnan');
        Summary(Ifields).ShiftY = median(diff(MatchedS(Ifields).Data.Y,1,1), 2, 'omitnan');
    
        % relative photometry
        if Args.RelPhot
            [ResZP(Ifields), MatchedS(Ifields)] = lcUtil.zp_lsq(MatchedS(Ifields), 'MagField',Args.MagCalibColName, 'MagErrField',Args.MagCalibErrColName);
            
            % apply ZP to all Magnitudes...
            %FFU
            
        end
        
        % lcUtil.fitPolyHyp
        if Args.fitPolyHyp
            [ResVar(Ifields).Result] = lcUtil.fitPolyHyp(MatchedS(Ifields), 'MagFieldNames',Args.MagCalibColName, 'PolyDeg',Args.PolyDeg, 'SubtractMeanT',true,'NormT',true);
        end

    end    
    
    % fit proper motion
    if Args.FitPM
        FitMotion = lcUtil.fitMotion(MatchedS, Args.fitMotionArgs{:});
    end
    
    MergedCat = AstroCatalog([Nfields 1]);
    %FunType   = str2func(class(MatchedS(1).getMatrix(Args.ColNameFlags)));
    
    for Ifields=1:1:Nfields    
        ColNames = {};
        ColUnits = {};
        Cat      = [];
        if Args.FitPM
            ColNames = {'RA','Dec','Nobs', 'StdRA','StdDec', 'PM_RA','PM_Dec', 'PM_DeltaChi2'};
            ColUnits = {'deg','deg','','deg','deg','deg/day','deg/day',''};
            
            Cat(:,1)       = FitMotion(Ifields).RA.ParH1(1,:).';
            Cat(:,2)       = FitMotion(Ifields).Dec.ParH1(1,:).';
            Cat(:,3)       = FitMotion(Ifields).RA.Nobs(:);
            Cat(:,4)       = FitMotion(Ifields).RA.StdResid_H0(:);
            Cat(:,5)       = FitMotion(Ifields).Dec.StdResid_H0(:);
            Cat(:,6)       = FitMotion(Ifields).RA.ParH1(2,:).';
            Cat(:,7)       = FitMotion(Ifields).Dec.ParH1(2,:).';
            Cat(:,8)       = (FitMotion(Ifields).RA.DeltaChi2 + FitMotion(Ifields).Dec.DeltaChi2).';
        end
        
        Icol = numel(ColNames) + 1;
        Cols(Ifields).Flags = combineFlags(MatchedS(Ifields),'FlagsNameDic',Args.ColNameFlags, 'FlagsType',@uint32);
        Cat(:,Icol) = Cols(Ifields).Flags.(Args.ColNameFlags)(:);
        
        Nstat = numel(Args.ColNamesStat);
        for Istat=1:1:Nstat
            Cols(Ifields).Stat.(Args.ColNamesStat{Istat}) = statSummary(MatchedS(Ifields),...
                                                                        'FieldNameDic',Args.ColNamesStat{Istat},...
                                                                        'FunInd',Args.FunIndStat{Istat});
            
            StatFieldNames = fieldnames(Cols(Ifields).Stat.(Args.ColNamesStat{Istat}));
            NstatFN = numel(StatFieldNames);
            for IstatFN=1:1:NstatFN
                Icol           = Icol + 1;
                Cat(:,Icol)    = Cols(Ifields).Stat.(Args.ColNamesStat{Istat}).(StatFieldNames{IstatFN})(:);
                ColNames{Icol} = sprintf('%s_%s',StatFieldNames{IstatFN}, Args.ColNamesStat{Istat});
                ColUnits{Icol} = MatchedS(Ifields).getUnits(Args.ColNamesStat{Istat});
            end
        end

        Nall = numel(Args.ColNamesAll);
        for Iall=1:1:Nall
            Cols(Ifields).All.(Args.ColNamesAll{Iall}) = MatchedS(Ifields).getMatrix(Args.ColNamesAll{Iall}).';
            [~,Ncol] = size(Cols(Ifields).All.(Args.ColNamesAll{Iall}));
            
            Cat(:,Icol+1:Icol+Ncol) = Cols(Ifields).All.(Args.ColNamesAll{Iall});
            %Icol = Icol + Ncol;
            for IcolEp=1:1:Ncol
                Icol = Icol + 1;
                ColNames{Icol} = sprintf('Epoch%03d_%s',IcolEp, Args.ColNamesAll{Iall});
                ColUnits{Icol} = MatchedS(Ifields).getUnits(Args.ColNamesAll{Iall});
            end
        end
       
        % ResVar
        Icol           = Icol + 1;
        Cat(:,Icol)    = ResVar(Ifields).Result(end).ResidStd(:);
        ColNames{Icol} = 'StdPoly';
        ColUnits{Icol} = 'mag';
        Icol           = Icol + 1;
        Cat(:,Icol)    = ResVar(Ifields).Result(end).DeltaChi2(:);
        ColNames{Icol} = 'PolyDeltaChi2';
        ColUnits{Icol} = '';
        
        MergedCat(Ifields).Catalog  = Cat;
        MergedCat(Ifields).ColNames = ColNames;
        MergedCat(Ifields).ColUnits = ColUnits;
        MergedCat(Ifields).sortrows('Dec');
        
        % treat unmatched sources
        %   select all sources with Nobs<3 || PM
        %   For each source:
        %       search all nearby selected sources w/o time overlap
        %       Fit PM with RANSAC
        %           If good solution - save connected source
        
        
        % match to external catalogs
        %   
        
    
        
    end
    
    
    % DEBUG
    %I= 9;
    %semilogy(nanmedian(MatchedS(I).Data.MAG_CONV_2,1),  nanstd(MatchedS(I).Data.MAG_CONV_2,[],1),'.')
    %hold on;
    %semilogy(nanmedian(CorrMS(I).Data.MAG_CONV_2,1),  nanstd(CorrMS(I).Data.MAG_CONV_2,[],1),'.')
    %semilogy(nanmedian(MatchedS(I).Data.MAG_CONV_2,1),  nanstd(MatchedS(I).Data.Dec,[],1).*3600,'.')
        
     
    
end