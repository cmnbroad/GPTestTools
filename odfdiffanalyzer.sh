#!/bin/sh
#
# Compare ODF file *datasets* row by row and column by column to determine how
# they differ. This script is currently not a generalized ODF file diff'er; it
# is mostly useful for analyzing files that are known to be different in order
# to determine the nature of those differences.
#
# Each row of the data set is compared column by column and the columns which
# differ are displayed along with the line number. The known/required
# metadata/header lines (ODF version, Datalines, Headerlines, etc.) are analyzed
# and compared, but the unknown/optional header lines are not.
#
# ***NOTE***: All comparisons are case-insensitive.
#
# Expected file format:
#
#   ODF 1.0
#   Headerlines=nn
#   Model=...
#   Datalines=nn
#   COLUMN_TYPES: String float...
#   COLUMN_DESCRIPTIONS: text...
#   RowNamesColumn=0
#   RowDescriptionsColumn=1
#   ...additional header lines (not inspected)
#   ...dataset lines...
#
# TODO:
#   Compare and analyze COLUMN_TYPES, COLUMND_DESCRIPTIONS, RowNamesColumn and
#   RowDescriptionColumn headerlines; these are currently ignored.
#   Use RowNamesColumn to identify row in output

# Check command line args
#
if [ "$#" != "2" ]  || ! [ -e "$1" ] || ! [ -e "$2" ]; then
    echo "Usage: $0 file1.odf file2.odf"
    exit 1
fi

# Compare input file line counts to make sure they match
#
f1count=(`wc -l $1`)
f2count=(`wc -l $2`)
echo ${f1count[0]} ${f2count[0]}
if [ ${f1count} != ${f2count[0]} ]; then
    echo "Line counts differ"
    exit -1
fi

# Paste the files together, process header lines, and compare
# each column of each row.
#
paste $1 $2 |
awk '
BEGIN {
    FS="[\t]"
    IGNORECASE=1
}

# Check and compare ODF version numbers
/^ODF/ {
    if (match($1, "[0-9.]+")) {
        ODFVersionL=substr($1, RSTART, RLENGTH)
        if (match($2, "[0-9.]+")) {
            ODFVersionR=substr($2, RSTART, RLENGTH)
            if (ODFVersionL != ODFVersionR) {
                print "Mismatch in ODF versions"
                exit
            }
            else {
                if (ODFVersionL != "1.0") {
                    print "Unsupported ODF Version: " ODFVersionL
                }
                print "ODF versions match!"
            }
        }
    }
}

/^Datalines=[0-9]+/ {
    if (match($1, "[0-9]+")) {
        DatalinesL=substr($1, RSTART, RLENGTH)
        if (match($2, "[0-9]+")) {
            DatalinesR=substr($2, RSTART, RLENGTH)
            if (DatalinesL != DatalinesR) {
                print "Mismatch in Headerlines"
                exit
            }
            else {
                print "Datalines match!"
            }
        }
    }
}

/^Headerlines=[0-9]+/ {
    if (match($1, "[0-9]+")) {
        Skiplines=substr($1, RSTART, RLENGTH)
        if (match($2, "[0-9]+")) {
            chkSkip=substr($2, RSTART, RLENGTH)
            if (chkSkip != Skiplines) {
                print "Mismatch in Headerlines"
                exit
            }
            else {
                print "Headerlines match!"
                Skiplines=Skiplines+2
            }
        }
    }
}

# Compare the actual datasets...
{
    # Skip the header lines
    if (NR > Skiplines) {
        for (i=1; i <= NF/2; i++) {
            rc = 0
            tfn = i+(NF/2)
            if ($i != $tfn) {
                if (rc == 0) {
                    printf("%s: ", NR)
                }
                printf("(%s : %s) ", $i, $tfn)
                rc++
            }
            if (rc != 0)
                printf("\n");
        }
    }
}'
                                                                                
