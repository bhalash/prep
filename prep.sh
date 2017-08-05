#!/usr/bin/env zsh

# The MIT License (MIT)
#
# Copyright (c) 2015 Mark Grealish (mark@bhalash.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#
# Functions
#

#
# Generate Image HTML Code
# figure>a>img[src="image", srcset="image"]
#

link_html() {
    # Image name without extension.
    local image_name=${1%.*}
    # Link alt and title text.
    local alt_text=${2:='FIXME'}
    # srcset image list.
    local srcset=''
    # Tentative breakpoint action.
    # local breakpoints="(min-width: ${responsive_sizes[-1]}) 100%"
    local breakpoints=''
    # URL of image, sans filename, size and extension.
    local image_url="${url_prefix}${url_domain}/${image_dir}/${thumbnail_folder}"
    # Link src and href.
    local src="${image_url}/${image_name}_${responsive_sizes[1]}.jpg"

    for n in $(seq 1 ${#responsive_sizes}); do
        size=${responsive_sizes[$n]}
        srcset+="${image_url}/${image_name}_${size}.jpg ${size}w"

        if [[ $n < ${#responsive_sizes} ]]; then
            srcset+=', '
        fi
    done

    link+="<a title=\"${alt_text}\" href=\"${src}\"><img src=\"${src}\" "
    link+="srcset=\"${srcset}\" sizes=\"${breakpoints}\" alt=\"${alt_text}\" /></a>"
    link+='
    '

    echo -e $link
}

#
# Compress Image for Web
# -quality        Reduce quality to 60%.
# -format         JPG format.
# -resize         Resize to ${size}, but only if bigger.
# -interlace      Progressively encode. See https://goo.gl/LyOJM7
# -filter         Apply a smoothing Lanzos filter.
# -strip          Strip all meta data.
# -define         Set a maximum output filesize of 150kb.
# ${filename:=$1} Set $filename to value of $1 if variable is empty.
#

resize_image() {
    local filename=''

    for size in $responsive_sizes; do
        filename="${1%.*}_${size}.jpg"
        cp $1 $filename

        mogrify -quality 70 -format jpg -resize "$size"x\> -interlace plane \
            -filter Lanczos -strip ${filename:=$1} &
    done
}

#
# Test if Executable Exists
#

has_executable() {
    which ${1%% *} > /dev/null 2>&1
    echo $?
}

#
# Send Text to Clipboard
#

to_clipboard() {
    local -a clipboards
    clipboards=('xclip -sel clip' 'pbcopy' 'putclip')

    # Dump the string to STDOUT if an appropriate clipboard program does not exist.
    local found_clipboard='cat'

    for prog in $clipboards; do
        if [[ $(has_executable $prog) == 0 ]]; then
            found_clipboard=$prog
            break
        fi
    done

    eval $found_clipboard <<< "$1"
}

#
# Debug
#

if [[ $1 == 'DEBUG' ]]; then
    set -x
    shift
fi

#
# Script Variables
#

# Incremented count of images.
count=1
# Pastable hyperlink.
html=''
# Config file.
conf=~/.config/prep/config
# Mandatory dependencies.
dependencies=('rsync' 'mogrify')

#
# Source Config File
#

if [[ ! -f $conf ]]; then
    echo "Error: Configuration file not found at ${conf}"
    exit 1
fi

source $conf

#
# Check Images and Executables Exist
#

if [[ $# -lt 2 ]]; then
    echo 'Error: Please provide at least one image and a folder!'
    exit 2
fi

for dependency in $dependencies; do
    if [[ $(has_executable $dependency) != 0 ]]; then
        echo "Error: ${dependency} executable not found in \$PATH"
        exit 3
    fi
done

#
# Setup Temp Directory
#

image_dir=$1
shift

if [[ $(has_executable 'mktemp') != 0 ]]; then
    temp="${TMPDIR}prep.$(date +%s)"
    mkdir $temp
else
    temp=$(mktemp -d)
fi

#
# Setup Thumbnail Directory
#

mkdir "${temp}/${thumbnail_folder}"

#
# Copy Images to Folders
#

for image in "$@"; do
    if [[ -e $image ]]; then
        # Replace filename with count, but preserve extension.
        cp "$image" "${temp}/${image//${image%.*}/${count}}"
        cp "$image" "${temp}/${thumbnail_folder}/${count}.jpg"
        let count++
    fi
done

cd "${temp}/${thumbnail_folder}"

#
# Main Loop
#

for img in *.jpg; do
    # Resize thumbnail images.
    resize_image $img
    # Add a line to the final HTML.
    html+=$(link_html $img)
done

# Wrap all link code in a single HTML5 figure element.
html="<figure>
${html}</figure>"

# Strip trailing whitespcae.
html=$(sed -e 's/^ *//g;s/<a/    <a/g' <<< $html)

if [[ -n $html ]]; then
    cd $temp

    # Add HTML to the clipboard.
    to_clipboard $html

    # If many images are queued to process the rest of the script can lag
    # behind mogrify.
    wait

    rsync -av --chmod=g+rwx -p . "${remote_server}:${remote_path}/${image_dir}" > /dev/null 2>&1 &
else
    echo 'Error: No valid images were processed by the script.'
    exit 4
fi
