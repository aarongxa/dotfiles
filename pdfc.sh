#!/bin/zsh
# pdfc: compress a PDF with Ghostscript. Usage: pdfc file.pdf [level]
f="$1"; lvl="$2"
if [[ -z "$f" ]]; then
  print "PDF Compress\n  1) ebook    good quality, smaller (default)\n  2) printer  high quality, 300 dpi\n  3) prepress best quality, keeps color profiles\n  4) screen   smallest, 72 dpi\n  5) custom   pick a dpi"
  read "f?PDF file: "; f="${f//\'/}"; f="${f%% }"
  read "c?Choice [1]: "; lvl=${${(s: :)${:-ebook printer prepress screen custom}}[${c:-1}]}
fi
[[ -f "$f" ]] || { print "File not found: $f"; exit 1; }
lvl=${lvl:-ebook}; out="${f%.*}_compressed.pdf"; extra=()
if [[ $lvl == custom ]]; then read "d?DPI [150]: "; d=${d:-150}; lvl=printer
  extra=(-dDownsampleColorImages=true -dColorImageResolution=$d -dGrayImageResolution=$d -dMonoImageResolution=$((d*2)))
fi
gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -dCompatibilityLevel=1.6 -dPDFSETTINGS=/$lvl -dDetectDuplicateImages=true -dCompressFonts=true $extra -sOutputFile="$out" "$f" || exit 1
a=$(stat -f%z "$f"); b=$(stat -f%z "$out")
if (( b >= a )); then cp "$f" "$out"; print "Already optimal, copied original to $out"; else
print "$out  $((a/1024))KB to $((b/1024))KB ($(( 100 - b*100/a ))% smaller)"; fi
