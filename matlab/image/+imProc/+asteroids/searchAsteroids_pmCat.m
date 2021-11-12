function CatPM = searchAsteroids_pmCat(CatPM, BitDict, Args)
    %
    % Example : imProc.asteroids.searchAsteroids_pmCat(MergedCat, AllSI(1).MaskData.Dict, 'ExpTime',range(JD), 'PM_Radius',3./3600)
    
    arguments
        CatPM AstroCatalog
        BitDict(1,1) BitDictionary
        Args.Images AstroImage
        
        Args.ColNameRA                    = 'RA';  % RA at central epoch
        Args.ColNameDec                   = 'Dec'; % Dec at central epoch
        Args.ColNamePM_RA                 = 'PM_RA';
        Args.ColNamePM_Dec                = 'PM_Dec';
        Args.ColNamePM_TdistProb          = 'PM_TdistProb';
        Args.ColNameNobs                  = 'Nobs';
        Args.ColNameFlags                 = 'FLAGS';
        
        Args.RemoveBitNames               = {'Saturated', 'Spike', 'CR_DeltaHT', 'CR_Laplacian', 'CR_Streak', 'Streak', 'Ghost', 'Persistent', 'NearEdge'};
        Args.ExpTime                      = [];  % same units as PM time
        Args.PM_Radius                    = [];  % same units as the PM
        
        % linking
        Args.LinkingRadius                = 2;
        Args.LonkingRadiusUnits           = 'arcsec';
        Args.AddLinkingCol logical        = true;
        Args.LinkingColName               = 'LinkedAsteroid';
        
    end
    
    LinkingRadiusRad = convert.angular(Args.LonkingRadiusUnits, 'rad', Args.LinkingRadius);
    
    %[MergedCat, MatchedS, Result] = pipeline.generic.mergeCatalogs(AllSI)
    
    Ncat = numel(CatPM);
    for Icat=1:1:Ncat
        % select columns from CatPM
        [Nsrc, Ncol] = sizeCat(CatPM(Icat));
    
        PM           = CatPM(Icat).getCol({Args.ColNamePM_RA, Args.ColNamePM_Dec});
        PM_TdistProb = CatPM(Icat).getCol(Args.ColNamePM_TdistProb);
        Nobs         = CatPM(Icat).getCol(Args.ColNameNobs);
        DecFlags     = CatPM(Icat).getCol(Args.ColNameFlags);
        
        TotPM        = sqrt(sum(PM.^2, 2));  % total PM [deg/day]
        ExpectedNobs = TotPM.*Args.ExpTime./(0.5.*Args.PM_Radius);
        
        % remove sources with some selected flags
        Flags(Icat).FLAGS  = ~findBit(BitDict, DecFlags, Args.RemoveBitNames, 'Method','any');
        Flags(Icat).Tdist  = ((PM_TdistProb > 0.995 & Nobs>5) | (PM_TdistProb>0.9999 & Nobs>3));
        Flags(Icat).Nobs   = Nobs>(0.9.*ExpectedNobs);
        Flags(Icat).All    = Flags.FLAGS & Flags.Tdist & Flags.Nobs;
        
        % Number of asteroid candidates
        AstInd   = find(Flags(Icat).All);
        NastCand = numel(AstInd);
        
        % Linking objects
        % Since PM epoch is the same for all objects
        % this involves only comparing the position of sources
        [RA, Dec] = CatPM(Icat).getLonLat('rad', 'ColLon',Args.ColNameRA, 'ColLat',Args.ColNameDec); % [rad]
        % select only the asteroid candidates
        RA  = RA(Flags(Icat).All);
        Dec = Dec(Flags(Icat).All);
        
        LinkedAstIndex       = 0;
        LinkedColumn         = nan(Nsrc, 1);  % nan - no PM | negative/unique(not necessely continous) - asteroid w/o links | >0 - asteroid with links
        LinkedColumn(AstInd) = -(1:1:numel(AstInd));
        if NastCand>1
            for Icand=1:1:NastCand
                Dist = celestial.coo.sphere_dist_fast(RA(Icand), Dec(Icand), RA, Dec);
                Dist(Icand) = NaN;

                FlagLink = Dist < SearchRadiusRad;
                if sum(FlagLink)>0
                    % found a match for asteroid 
                    LinkedAstIndex = LinkedAstIndex + 1;

                    % mark the linked sources as the same asteroid (same
                    % index)
                    LinkedColumn(AstInd(Icand)    = LinkedAstIndex;
                    LinkedColumn(AstInd(FlagLink) = LinkedAstIndex;
                end
            end
        end
        
        if Args.AddLinkingCol
            CatPM(Icat).insertCol(LinkedColumn, Args.LinkingColName, '');
        end
        
        
        % extract cutouts centered on asteroids candidates
        if ~isempty(Args.Images) 
            % for eack linked source
            find(LinkedColumn == 0);
            UniquAst = nique(LinkedColumn);
            UniquAst = UniquAst(~isnan(UniquAst));
            Nunique  = numel(UniquAst);
            for Iun=1:1:Nunique
                % for each unique asteroid
                % extract a cutout from Args.Images
            
            
            
            end
        end
    end
        
    
    %          I = 1; AA=MergedCat(I).toTable; Flag = (AA.PM_TdistProb>0.999 & AA.Nobs>5) | (AA.PM_TdistProb>0.9999 & AA.Nobs>3); remove near edge..., 
    % check that motion is consistent with Nobs sum(Flag)
    %          ds9(AllSI(1,I), 1); 
    %          ds9(AllSI(end,I), 2); 
    %          ds9.plot(MergedCat(I).Catalog(Flag,1:2),'o','Coo','fk5')
    
    
end
