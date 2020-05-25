import argparse
import contextlib
import math
import os
import subprocess
import tarfile
import tempfile

import cairosvg
import PIL

parser = argparse.ArgumentParser(
    description='Rasterize the layers from an SVG into a .fnt file')
parser.add_argument('-o', '--output-dir', default='.',
    help='Output directory to generate files')
parser.add_argument('-t', '--tar-file', required=True,
    help='Tar file to take layers from'),
parser.add_argument('size',
    help='Size (in pixels) to generate fonts with')

@contextlib.contextmanager
def enter_directory(dirname):
    old_wd = os.getcwd()
    os.chdir(dirname)
    try:
        yield dirname
    finally:
        os.chdir(old_wd)

char_map = dict(
    v='arrow_paste',
    l='arrow_lists',
    t='arrow_tasks',
    x='arrow_x',
    g='settings_gear',
    n='phone_code',
    W='world',
    f='frown',
    s='smile',
    w='watch',
)
glyph_chars = list(char_map)
for (k, v) in list(char_map.items()):
    char_map[v] = k

def main(args=None):
    args = parser.parse_args(args)
    tile_size = int(args.size)

    tiles_per_row = int(math.ceil(math.sqrt(len(glyph_chars))))
    num_rows = (len(glyph_chars) + tiles_per_row - 1)//tiles_per_row
    image_width = tiles_per_row*tile_size
    image_height = num_rows*tile_size

    font_png = PIL.Image.new('L', (image_width, image_height))

    fnt_lines = []
    fnt_lines.append('info face="icon_glyphs_{}" size={} bold=0 italic=0 '
                     'charset="" unicode=0 stretchH=100 smooth=1 aa=1 '
                     'padding=0,0,0,0 spacing=0,0'.format(tile_size, tile_size))
    fnt_lines.append('common lineHeight={size} base={size} scaleW={w} '
                     'scaleH={h} pages=1 packed=0'.format(
                         size=tile_size, w=font_png.width, h=font_png.height))
    fnt_lines.append('page id=0 file="icon_font_{}.png"'.format(tile_size))
    fnt_lines.append('chars count={}'.format(len(glyph_chars)))

    png_names = {}
    with contextlib.ExitStack() as st:
        t = st.enter_context(tarfile.open(args.tar_file, 'r'))
        tempdir = st.enter_context(tempfile.TemporaryDirectory())
        st.enter_context(enter_directory(tempdir))

        t.extractall()

        for entry in t:
            layer_name = entry.name.split('.')[0]
            if layer_name not in char_map:
                continue
            target_glyph = char_map[layer_name]

            png_name = entry.name.replace('svg', 'png')
            png_names[target_glyph] = png_name

            with open(entry.name, 'r') as f, open(png_name, 'wb') as out:
                cairosvg.svg2png(file_obj=f, write_to=out,
                                 output_height=tile_size, output_width=tile_size)

        for (i, char) in enumerate(sorted(glyph_chars, key=ord)):
            with PIL.Image.open(png_names[char]) as img:
                (_, _, _, a) = img.split()
                row = i//(font_png.width//tile_size)
                col = i%(font_png.width//tile_size)
                x, y = col*tile_size, row*tile_size
                font_png.paste(a, (x, y))

                fnt_lines.append(' '.join(
                    ['char', 'id={}'.format(ord(char)), 'x={}'.format(x),
                     'y={}'.format(y), 'width={}'.format(tile_size),
                     'height={}'.format(tile_size), 'xoffset=0', 'yoffset=0',
                     'xadvance={}'.format(tile_size), 'page=0', 'chnl=0'
                   ]))

        fnt_lines.append('kernings count=0')

    png_name = os.path.join(args.output_dir, 'icon_font_{}.png'.format(tile_size))
    fnt_name = os.path.join(args.output_dir, 'icon_font_{}.fnt'.format(tile_size))
    font_png.save(png_name)
    with open(fnt_name, 'w') as f:
        f.write('\n'.join(fnt_lines))

if __name__ == '__main__': main()
