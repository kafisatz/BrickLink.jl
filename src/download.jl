export download_images
function download_images(df::DataFrames.DataFrame,imgfldr::String)
    if !isdir(imgfldr)
        @warn("Folder does not exist\r\n$(imgfldr)")
        return nothing
    end
    for i=1:size(df,1)
        
        imgurl = df.imgurl[i]
        imgname = string(df.item[i],".jpg")
        #remove string after -
        imgname = split(imgname,"-")[1] * ".jpg"
        imgpath = joinpath(imgfldr,imgname)
        if !isfile(imgpath)
            if !(stat(imgpath).size > 10_000)
                @info("Downloading image $(i) of $(size(df,1))")
                download(imgurl,imgpath)
            end
        end
    end
end

