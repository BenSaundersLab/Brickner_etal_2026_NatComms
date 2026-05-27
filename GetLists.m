function [FoundLists] = GetLists (inputdata,varargin)
%A Wolff 15/2/21
%takes input and separates into lists with each item of list in new cell based on commas as a file separator. 
%Default is a text list, can additionally input the format specifier for the list -if multiple lists in input specifier is required for each list ('%f') for floating point,('%i)for integer
%can do this for multiple lists in single input butseparate lists should be contained within square brackets [,,,,] and separated with
%if only one list then comma separated values are fine (no square brackets required)
if nargin > 1;
    convertformat = true;
    listtype = varargin;
else
    convertformat = false;
end
listindx_s = strfind(inputdata,'['); %search for file separator for multiple lists
listindx_e = strfind(inputdata,']');
if isempty(listindx_s) && isempty(inputdata) %if there are not multiple lists save cell as empty
FoundLists{1,1} = []; 
else 
    if isempty(listindx_s) %if there are no list separators and the input is not empty assume 1 list
    nlists = 1;
    listindx_s = 0;
    listindx_e = length(inputdata)+1;
    else
    nlists = length(listindx_s);
    end
    FoundLists = cell(1,nlists);
    for listn= 1:nlists %for each list separate out list items into individual cells for reading later   
    currentlist = inputdata(listindx_s(listn)+1:listindx_e(listn)-1);
    if isempty (currentlist)
    FoundLists{1,listn} = [];   
    else
    filesepindx = strfind(currentlist,',');
        if isempty(filesepindx)%if there are no commas, but the list is not empty,assume only 1 item on list
         FoundLists{1,listn}{1} = currentlist;
         FoundLists{1,listn}{1} = strrep(FoundLists{1,listn}{1},' ','');
                if convertformat && length(listtype)>=listn %if listtype is non-text and a specifier is provided
                    FoundLists{1,listn}{1}= sscanf(FoundLists{1,listn}{1},listtype{listn});
                end
        else %otherwise separate items into separate cells
            s_indx = 1;
            for item = 1:length(filesepindx)+1
                if item <= length(filesepindx)
                FoundLists{1,listn}{item} = currentlist(s_indx:filesepindx(item)-1);
                FoundLists{1,listn}{item} = strrep(FoundLists{1,listn}{item},' ','');
                if convertformat && length(listtype)>=listn %if listtype is non-text and a specifier is provided
                    FoundLists{1,listn}{item}= sscanf(FoundLists{1,listn}{item},listtype{listn});
                end
                s_indx = filesepindx(item) + 1;
                else %for last item
                    if ~isempty(currentlist(s_indx:end))
                    FoundLists{1,listn}{item} = currentlist(s_indx:end);
                    FoundLists{1,listn}{item} = strrep(FoundLists{1,listn}{item},' ','');
                        if convertformat && length(listtype)>=listn  %if listtype is non-text
                        FoundLists{1,listn}{item}= sscanf(FoundLists{1,listn}{item},listtype{listn});
                        end
                    end 
                end
            end
        end
    end
    end
end
end