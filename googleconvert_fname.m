function[fname] = googleconvert_fname(fname,googlepath)
        fsep = filesep;
        indx = strfind(fname,'Shared drives');
        if ~isempty(indx)
        fname = strcat(googlepath,fsep,fname(indx:end));
        end
end


