function Result = zp_external(Obj, Args)
    %
   
    arguments
        Obj MatchedSources

        Args.FieldFlux                    = 'FLUX_PSF';
        Args.FieldErr                     = 'MAGERR_PSF';
        Args.IsMag logical                = false;
        Args.FunConvertErr                = @(F) F./1.086;    % conversion to relative error
        Args.FieldRefMag                  = 'phot_bp_mean_mag';
        Args.FieldRefMagErr               = 'phot_bp_mean_flux_over_error';
        Args.FunConvertRefErr             = @(F) 1.086./F;    % conversion to relative error

        Args.FluxErrRange                 = [0.003 0.2];

%         Args.CalibFun function_handle     =
%         Args.CalibFunArgs function_handle = {};
%         
%         Args.FieldMagExternal             = {};      % if not in MatchedSources than query ExternalCat
%         Args.FieldMagErrExternal          = {};      % if not in MatchedSources than query ExternalCat
%         Args.FieldMagMeasured             = 'MAG_PSF';
%         Args.FieldMagErrMeasured          = 'MAGERR_PSF';
%         
%         Args.FieldRA                      = 'RA';
%         Args.FieldDec                     = 'Dec';
%         Args.CooUnits                     = 'deg';
%         
%         
%         Args.CalibCat                     = 'GAIADR3';
%         Args.MatchRadius                  = 3;
%         Args.MatchRadiusUnits             = 'arcsec';
%         
        Args.CreateNewObj logical         = true;
        Args.UpdateMagFields              = {'FLUX_PSF'};
    end
    
    if Args.CreateNewObj
        Result = Obj.copy;
    else
        Result = Obj;
    end
    
    Nupdate = numel(Args.UpdateMagFields);
    
    Nobj = numel(Obj);
    for Iobj=1:1:Nobj
        % for each MatchedSources object
        
        Nepoch = Obj(Iobj).Nepoch;
        Nsrc   = Obj(Iobj).Nsrc;
        
        RefMag    = Obj(Iobj).SrcData.(Args.FieldRefMag);
        % convert to flux
        if Args.IsMag
            error('IsMag true option is not yet available');
        end
        RefMagErr = Obj(Iobj).SrcData.(Args.FieldRefMagErr);
        RefMagErr = Args.FunConvertRefErr(RefMagErr);

         
        
        InstFlux    = Obj(Iobj).Data.(Args.FieldFlux);
        InstFluxErr = real(Obj(Iobj).Data.(Args.FieldErr));
        
        FlagGoodRef = RefMagErr<0.1 & InstFlux>0 & InstFluxErr>min(Args.FluxErrRange); % & InstFluxErr<max(Args.FluxErrRange);
        
        Nref = sum(FlagGoodRef,2);
        
        
        
        
        RefMagMat               = RefMag.*FlagGoodRef;
        RefMagMat(RefMagMat==0) = NaN;
        RefFluxMat              = 10.^(-0.4.*RefMagMat);
        
        
        
        FluxRatio = RefFluxMat./InstFlux;
        MeanFR = median(FluxRatio,2,'omitnan');
        StdFR = std(FluxRatio,[],2,'omitnan');
        ErrFR = StdFR./sqrt(Nref);
       
        for Iupdate=1:1:Nupdate
            Result(Iobj).Data.(Args.UpdateMagFields{Iupdate}) = Obj(Iobj).Data.(Args.UpdateMagFields{Iupdate}).*MeanFR;
        end

        
    end


end