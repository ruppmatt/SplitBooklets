#!/bin/bash

# Matthew Rupp 2019


# ANSI color codes
RS="\033[0m"    # reset
HC="\033[1m"    # hicolor
UL="\033[4m"    # underline
INV="\033[7m"   # inverse background and foreground
FBLK="\033[30m" # foreground black
FRED="\033[31m" # foreground red
FGRN="\033[32m" # foreground green
FYEL="\033[33m" # foreground yellow
FBLE="\033[34m" # foreground blue
FMAG="\033[35m" # foreground magenta
FCYN="\033[36m" # foreground cyan
FWHT="\033[37m" # foreground white
BBLK="\033[40m" # background black
BRED="\033[41m" # background red
BGRN="\033[42m" # background green
BYEL="\033[43m" # background yellow
BBLE="\033[44m" # background blue
BMAG="\033[45m" # background magenta
BCYN="\033[46m" # background cyan
BWHT="\033[47m" # backgrouwnd white


_log()
{
   printf -- "$@\n"
}

_log_warn()
{
   printf -- "${FCYN}$@${RS}\n"
}

_log_error()
{
   printf -- "${FRED}$@${RS}\n"
}
   

show_help(){
   _log "This utility splits a PDF into a number of 'booklets' of the same"
   _log "size."
   _log
   _log "Usage: -src INPUT_PDF -dst DEST_PREFIX -n NUMBER_OF_BOOKLETS"
   _log
   _log "Where INPUT_PDF is the path to the PDF containing all the booklets;"
   _log
   _log "DEST_PREFIX is the path prefix for where to place the files. It is"
   _log "suffixed with a zero-padded integer count and a pdf file suffix when"
   _log "files are output;"
   _log
   _log  "And NUMBER_OF_BOOKLETS is the number of booklets to extract from"
   _log  "the original PDF."
   _log
   _log "Flags:"
   _log
   _log "       -h | --help"
   _log "               Display this message."
   _log
   _log "       -source | --source | -src | --src"
   _log "               The following argument is the source PDF path"
   _log
   _log "       -output | --output | -dst | --dst"
   _log "               The following argument is the output path prefix"
   _log "               for the individual booklet PDFs"
   _log
   _log "       -n | --num | -booklets | --booklets"
   _log "               The following argument is the number of booklets in"
   _log "               the source PDF."
}



parse_args(){
   set -- "${argv[@]}"
   while (( "$#" )); do
     case "$1" in
        -h|--help)
            MODE="help"
            shift 1
            return 0
            ;;

         -source|--source|-src|--src)
            if [ -z "$2" ]; then
               _log_error "source requires path to booklet"
               return 1
            fi
            SOURCE_PDF="$2"
            shift 2
            ;;

         -output|--output|-dst|--dst)
            if [ -z "$2" ]; then
               _log_error "destination requires a prefix to a path"
               return 1
            fi
            OUTPUT_PREFIX="$2"
            shift 2
            ;;

         -n|--num|-booklets|--booklets)
            if [ -z "$2" ]; then
               _log_error "number of booklets requires a number"
            fi
            BOOKLET_NUM="$2"
            shift 2
            ;;

         *)
            _log_error "Unrecognized option $1.  Abort."
            return 1
            ;;
      esac
   done      
}


do_split(){
   _log "Splitting ${SOURCE_PDF}"
   _log "into ${BOOKLET_NUM} booklets prefixed as"
   _log "${OUTPUT_PREFIX}"

   PAGES_NUM=$(pdftk "${SOURCE_PDF}" dump_data | awk '$0 ~/NumberOfPages:/{print $2}')
   if [ $? -ne 0 ]; then
      _log_error "Unable to determine the number of pages in the SOURCE_PDF"
      _log_error "${SOURCE_PDF}"
      return 1
   fi

   echo "Found ${PAGES_NUM} pages."
   local page_check
   local b_size
   ((page_check = PAGES_NUM % BOOKLET_NUM))
   ((b_size = PAGES_NUM / BOOKLET_NUM))
   if [ "${page_check}" -ne "0" ]; then
      _log_error "The number of pages in the source document (${PAGES_NUM})"
      _log_error "is inconsistent with the number of booklets (${BOOKLET_NUM})"
   fi

   local num_width="${#BOOKLET_NUM}"
   local num_fmt="%0${num_width}d"
   local b_cur
   local page_begin
   local page_end
   for (( b_cur=0; b_cur < "${BOOKLET_NUM}"; b_cur++ )); do
      printf "."
      (( page_begin = b_cur * b_size + 1))
      (( page_end = page_begin + b_size - 1 ))
      local pad_num=$(printf -- "$num_fmt" "${b_cur}")
      local file_out="${OUTPUT_PREFIX}-${pad_num}.pdf"
      pdftk "${SOURCE_PDF}" cat ${page_begin}-${page_end} output "${file_out}"
   done
}


do_main(){
   if ! parse_args "$*"; then
      return 1
   fi
   if [ "${MODE}" == "help" ]; then
      show_help
      return 0
   fi
   if [ -z "${SOURCE_PDF}" ]; then
      _log_error "SOURCE_PDF (--source) is not set."
      show_help
      return 1
   fi
   if [ -z "${OUTPUT_PREFIX}" ]; then
      _log_error "OUTPUT_PREFIX (--output) is not set."
      show_help
      return 1
   fi
   if [ -z "${BOOKLET_NUM}" ]; then
      _log_error "BOOKLET_NUM (--num) is not set."
      show_help
      return 1
   fi
   if ! which pdftk > /dev/null 2>&1; then
      _log_error "pdftk must be installed."
      return 1
   fi

   do_split
}


# Preserve our args since we're parsing them
# in their own function and need to preserve
# whitespace
# :-(
i=0
argv=()
for arg in "$@"
do
    argv[$i]="${arg}"
    i=$((i + 1))
done
do_main
