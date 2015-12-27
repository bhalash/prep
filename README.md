## prep
[prep](https://github.com/bhalash/prep) is a zshell script which I used to gather, crop, compress and upload images to my blog, as well as generate the HTML code and add it to my clipboard.

### Configuration
[config.sample](/config.sample) contains an example configuration for prep:

    # Save to ~/.config/prep/config and add your settings.

    # Name of image thumbnail folder.
    thumbnail_folder='m'

    # SSH username@server (or alias) and remote path.
    remote_server='user@server'
    remote_path='/var/www/example.com'

    # Image hyperlink prefix and domain name.
    url_prefix='https://'
    url_domain='example.com'

    # Responsive image sizes.
    responsive_sizes=(1024 840 768 640 424)

You should save this configuration file to `~/.config/prep/config` and populate it with values for your server.

### Dependencies
* [ImageMagick](http://www.imagemagick.org/script/index.php).
* [scp](http://linux.die.net/man/1/scp).
* [xclip](http://linux.die.net/man/1/xclip) (Linux)/[putclip](http://gnuwin32.sourceforge.net/packages/cygutils.htm) (Cygwin).

### Use
Simple:

    prep <folder name> <file 1> <file 2> <file 3> ... <file 10>

### Output
Code along this line will be added to your clipboard, ready to paste into a blog post:

    <a title="CHANGE ME" href="https://example.com/folder/m/1_840.jpg">
        <img src="https://example.com/folder/m/1_840.jpg" srcset="https://example.com/folder/m/1_840.jpg 840w, https://example.com/folder/m/1_768.jpg 768w, https://example.com/folder/m/1_640.jpg 640w, https://example.com/folder/m/1_424.jpg 424w" alt="CHANGE ME" />
    </a>

The HTML will be echoed instead if a clipboard program is not available on your system.

The file structure is (assuming default names):

    folder
    ├── 1.jpg
    └── m
        ├── 1.jpg
        ├── 1_424.jpg
        ├── 1_640.jpg
        ├── 1_768.jpg
        └── 1_840.jpg

### TODO
* Spawn default configuration if one does not exist.
* Robustify configuration in general.
* Robustify upload and add alternate options (copy to local folder, or use FTP, etc.).

### License
Prep is available under the [MIT License](https://opensource.org/licenses/MIT). Go wild.

### Support
None whatsoever. I disclaim all responsibility for the risk that prep might eat your hard disk or impact your libido.
