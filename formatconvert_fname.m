function[fname] = formatconvert_fname(fname)
    fsep = filesep;
    if fsep == '/'
    indx = find(fname =='\');
    else
    indx = find(fname == '/');
    end
    fname(indx)= fsep;      
end
