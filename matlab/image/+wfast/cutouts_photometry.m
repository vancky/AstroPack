function cutouts_photometry(Input, Args)
    %
    % Examples: AI =
    %          wfast.read2AstroImage('WFAST_Balor_20200801-020630-880_F505W_0_CutoutsStack.h5z','ReadType','cutouts','calibrate',false,'InterpOverNan',false);
    
    
    
    arguments
        Input                                    % AstroImage or file name
        Args.read2AstroImageArgs cell          = {'Calibrate',true,'InterpOverNan',false};
        Args.AperRadius(1,:)                   = [2, 3, 4];
        Args.Annulus(1,2)                      = [4 6];
        Args.SubBack(1,1) logical              = true;
    end
    
    if ~isa(Input, AstroImage)
        % read FileName into an AstroImage object
        [AI, CalibObj] = read2AstroImage(Input, Args.read2AstroImageArgs{:},'ReadType','cutouts');
    else
        AI = Input;
    end
    
    Nobj = numel(Obj);
    for Iobj=1:1:Nobj
        SizeC = size(AI(Iobj).Image);
        Ncut  = prod(SizeC(3:end));
        Cube = reshape(AI(Iobj).Image, SizeC(1), SizeC(2), Ncut);
        X    = ceil(SizeC(2).*0.5).*ones(Ncut,1);
        Y    = ceil(SizeC(1).*0.5).*ones(Ncut,1);
        Cube = single(Cube);
        
        % with 1st moment estimation (Centered)
        [M1C(Iobj),M2C(Iobj),AperC(Iobj)] = imUtil.image.moment2(Cube, X, Y, 'NoWeightFirstIter',false,...
                                                                             'AperRadius',Args.AperRadius,...
                                                                             'Annulus',Args.Annulus,...
                                                                             'SubBack',Args.SubBack);
    
        % without 1st moment estimation (Forced)
        [M1F(Iobj),M2F(Iobj),AperF(Iobj)] = imUtil.image.moment2(Cube, X, Y, 'NoWeightFirstIter',false,'MaxIter',-1,...
                                                                             'AperRadius',Args.AperRadius,...
                                                                             'Annulus',Args.Annulus,...
                                                                             'SubBack',Args.SubBack);
    
        
        %
        M1C(Iobj)   = tools.struct.reshapeFields(M1C(Iobj), SizeC(3:end), 'first');
        M1F(Iobj)   = tools.struct.reshapeFields(M1F(Iobj), SizeC(3:end), 'first');
        M2C(Iobj)   = tools.struct.reshapeFields(M2C(Iobj), SizeC(3:end), 'first');
        M2F(Iobj)   = tools.struct.reshapeFields(M2F(Iobj), SizeC(3:end), 'first');
        AperC(Iobj) = tools.struct.reshapeFields(AperC(Iobj), SizeC(3:end), 'first');
        AperF(Iobj) = tools.struct.reshapeFields(AperF(Iobj), SizeC(3:end), 'first');
        
        
    end
end