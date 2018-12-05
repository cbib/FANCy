import sys
import glob
from subprocess import check_output
from os import path,makedirs


def run_tango(tango_path,this_path,matchfiles_dir,output_dir):

    # check if tango dir exists in output directory, if not create it:
    if not path.isdir(this_path + '/' + output_dir + '/tango'):
        makedirs(this_path + '/' + output_dir + '/tango')

    for matchfile in glob.glob(matchfiles_dir + '/*'):

        # addition of split to avoid storing the matchfiles_dir in matchfile object
        # if matchfile is 'matchfiles_dir.../X.match', keep only name of matchfile after last/:
        if "/" in matchfile:
            matchfile = matchfile.split('/')[-1]

        print '--- Running tango on {} ---'.format(matchfile)
        # Added path to the Tango libs using -I
        check_output(['perl',
            '-I', this_path + '/tango',
            this_path + '/tango/tango.pl',
            '--q-value', '0.5',
            '--taxonomy', this_path + 'data/UNITE.prep',
            '--matches',  matchfiles_dir + '/' + matchfile,
            '--output',  output_dir + '/tango/' + matchfile])




if len(sys.argv) == 5:
        run_tango(sys.argv[4], sys.argv[1], sys.argv[2], sys.argv[3])
else:
        print "\n\nError in run_tango arguments:"
        print "There should be 4 command line arguments (cur_dir, matchfiles_dir, output_dir, tango_dir)"
        print "Example:"
        print "python run_tango.py /current/dir /matchfiles/dir /output/dir tango/dir"
