function file_compare(file1, file2)
    filesize(file1) == filesize(file2) || return false
    return read(file1, String) == read(file2, String)
end

const SCRIPT_FILENAME = "keycounter.sh"
const SCRIPT_FILE_PATH = "../scripts"
const SCRIPT_PATH = "/usr/local/bin"

function install()
    src = joinpath(@__FILE__, SCRIPT_FILE_PATH, SCRIPT_FILENAME)
    dest = joinpath(SCRIPT_PATH, SCRIPT_FILENAME)
    try
        cp(src, dest)
    catch e
        if e isa IOError
            e.code == -2 && @error "Installation failed, missing script file"
            e.code == -13 && @error "Installation failed, retry with root permissions"
            return
        end
        e isa ArgumentError || rethrow(e)
        # e isa ArgumentError means that destination already exists
        file_compare(src, dest) || @error "Installation failed, a different file already exists at $dest"
        return
    end
    @info "Installation successful"
end

function uninstall()
    src = joinpath(@__FILE__, SCRIPT_FILE_PATH, SCRIPT_FILENAME)
    dest = joinpath(SCRIPT_PATH, SCRIPT_FILENAME)
    try
        if !file_compare(src, dest)
            @error "Cannot uninstall, $dest was not installed by this program"
        end
        rm(dest)
    catch e
        if e isa IOError
            e.code == -2 && @warn "File missing, perhaps already uninstalled?"
            e.code == -13 && @error "Cannot uninstall, retry with root permissions"
            return
        end
        rethrow(e)
    end
    @info "Successfully uninstalled"
end
