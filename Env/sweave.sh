
R=/usr/bin/R
# `mktemp -d make_docs_XXXX` || exit 1
DIR=$1
FILES=`ls *.Rnw`


if [ ! -d $DIR ]
then
  mkdir $DIR
fi

echo "PARAMETERS"
echo "=========="
echo "DIRECTORY ...... $DIR"
echo ""
echo ""


for fi in $FILES
do
  base=`basename $fi .Rnw`

  echo "Sweaving $fi"
  $R CMD Sweave $fi

  echo "Moving $base.tex to $DIR/$base.tex"
  mv $base.tex $DIR/$base.tex
done
